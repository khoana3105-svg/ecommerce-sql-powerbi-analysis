"""Build the SSMS loader and independent expected results from the supplied dump.

Python standard library only. Reads the SQL file as data, never executes it.
Run: python ecommerce_practice/src/prepare_practice.py
"""
from pathlib import Path
from collections import Counter, defaultdict
from decimal import Decimal
from datetime import datetime
import csv
import hashlib
import json
import re

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT
SOURCE = PROJECT / 'data/source/ecommerce-sample-database-v1-sql-mssql.sql'
ACCEPTED = {'paid', 'shipped', 'delivered'}


def statements(text):
    """Split at semicolons outside SQL strings; ignore line comments outside strings."""
    parts = []
    quoted = False
    i = 0
    while i < len(text):
        char = text[i]
        if not quoted and text[i:i+2] == '--':
            end = text.find('\n', i)
            i = len(text) if end < 0 else end
            continue
        parts.append(char)
        if char == "'":
            if quoted and text[i:i+2] == "''":
                parts.append("'")
                i += 2
                continue
            quoted = not quoted
        if char == ';' and not quoted:
            yield ''.join(parts).strip()
            parts.clear()
        i += 1
    if quoted or ''.join(parts).strip():
        raise ValueError('Unterminated SQL statement/string')


def parse_dump(text):
    tables = defaultdict(list)
    token = re.compile(r"\s*(N?'(?:''|[^'])*'|NULL|-?\d+(?:\.\d+)?|[(),])", re.S)
    for statement in statements(text):
        if not statement.startswith('INSERT INTO'):
            continue
        match = re.fullmatch(r'INSERT INTO (?:dbo\.)?\[(\w+)\] \((.*?)\) VALUES\s*(.*);', statement, re.S)
        if not match:
            raise ValueError('Unsupported INSERT format')
        table, fields, values = match.groups()
        columns = re.findall(r'\[(\w+)\]', fields)
        pos = 0
        tokens = []
        while pos < len(values):
            found = token.match(values, pos)
            if not found:
                if values[pos:].strip():
                    raise ValueError(f'Unsupported token in {table}: {values[pos:pos+40]}')
                break
            tokens.append(found.group(1))
            pos = found.end()
        index = 0
        while index < len(tokens):
            assert tokens[index] == '('
            index += 1
            row = []
            while True:
                value = tokens[index]
                if value.startswith(("N'", "'")):
                    start = 2 if value.startswith("N'") else 1
                    value = value[start:-1].replace("''", "'")
                elif value == 'NULL':
                    value = None
                else:
                    value = Decimal(value) if '.' in value else int(value)
                row.append(value)
                index += 1
                separator = tokens[index]
                index += 1
                if separator == ')':
                    break
                assert separator == ','
            assert len(row) == len(columns)
            tables[table].append(dict(zip(columns, row)))
            if index < len(tokens):
                assert tokens[index] == ','
                index += 1
    return dict(tables)


def write_csv(name, columns, rows):
    with (PROJECT / 'outputs' / name).open('w', encoding='utf-8', newline='') as stream:
        writer = csv.writer(stream, lineterminator='\n')
        writer.writerow(columns)
        writer.writerows(rows)


def build_loader(source_text, tables):
    assert source_text.count('BEGIN TRANSACTION;') == 1
    assert source_text.count('COMMIT;') == 1
    assert not re.search(r'^\s*GO\s*$', source_text, re.M)
    body = source_text.replace('BEGIN TRANSACTION;', '', 1).replace('COMMIT;', '', 1)
    checks = '\n'.join(
        f"    IF (SELECT COUNT_BIG(*) FROM dbo.[{table}]) <> {len(rows)}\n"
        f"        THROW 50102, 'Row count mismatch: {table}', 1;"
        for table, rows in tables.items())
    loader = '''/* Generated from the supplied SQL dump; original file is unchanged.
   SSMS: Execute this ENTIRE file once. No SQLCMD mode or file path editing needed.
   Database: EcommerceSalesPortfolio. If any user table exists, stop without loading.
   Requires permission to create/use this practice database. Do not select a production DB.
*/
USE master;
GO
IF DB_ID(N'EcommerceSalesPortfolio') IS NULL
    EXEC(N'CREATE DATABASE EcommerceSalesPortfolio');
GO
USE EcommerceSalesPortfolio;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE is_ms_shipped = 0)
    THROW 50101, 'Database already contains tables. Stop to avoid duplicate loading.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
'''
    # Explicit schema names prevent dependence on the importing user's default schema.
    for keyword in ['CREATE TABLE', 'INSERT INTO', 'ALTER TABLE', 'REFERENCES', 'SET IDENTITY_INSERT']:
        body = re.sub(r'(' + keyword + r') \[(\w+)\]', r'\1 dbo.[\2]', body)
    loader += body + '\n' + checks + '''
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
SELECT DB_NAME() AS PracticeDatabase, COUNT(*) AS ImportedTables
FROM sys.tables WHERE is_ms_shipped = 0;
'''
    (PROJECT / 'sql' / '01_tao_va_nap.sql').write_text(loader, encoding='utf-8-sig')


def main():
    (PROJECT / 'outputs').mkdir(parents=True, exist_ok=True)
    (PROJECT / 'sql').mkdir(exist_ok=True)
    text = SOURCE.read_text(encoding='utf-8-sig')
    tables = parse_dump(text)
    indexed = {table: {row['id']: row for row in rows} for table, rows in tables.items()}
    assert len(tables) == len(re.findall(r'CREATE TABLE \[', text))
    assert all(len(indexed[t]) == len(rows) for t, rows in tables.items())
    # Match exactly the single-column foreign-key declarations in this dump.
    foreign_keys = re.findall(r'ALTER TABLE \[(\w+)\][^;]*?FOREIGN KEY \(\[(\w+)\]\) REFERENCES \[(\w+)\] \(\[(\w+)\]\)', text)
    assert len(foreign_keys) == text.count('FOREIGN KEY')
    fk_issues = []
    for table, column, parent, key in foreign_keys:
        valid = {row[key] for row in tables[parent]}
        bad = sum(row[column] is not None and row[column] not in valid for row in tables[table])
        if bad:
            fk_issues.append([table, column, bad])
    assert not fk_issues, fk_issues
    # Check declared nullability, unique columns and nvarchar length before generating loader.
    for table, definition in re.findall(r'CREATE TABLE \[(\w+)\] \((.*?)\);', text, re.S):
        for column, kind, length, suffix in re.findall(
                r'\[(\w+)\] (\w+)(?:\(([^)]*)\))?([^\n]*)', definition):
            vals = [row[column] for row in tables[table]]
            if 'NOT NULL' in suffix or 'PRIMARY KEY' in suffix:
                assert all(v is not None for v in vals), (table, column, 'null')
            if 'UNIQUE' in suffix:
                assert len(vals) == len(set(vals)), (table, column, 'duplicate')
            if kind == 'nvarchar':
                assert all(v is None or len(v.encode('utf-16-le'))//2 <= int(length) for v in vals)
    orders, items, payments = tables['orders'], tables['order_items'], tables['payments']
    statuses = {r['id']: r['status_name'] for r in tables['order_statuses']}
    payments_by_order = {r['order_id']: r for r in payments}
    gross = defaultdict(Decimal)
    item_taxes = defaultdict(Decimal)
    for r in items:
        gross[r['order_id']] += r['quantity'] * r['unit_price']
        item_taxes[r['order_id']] += r['tax_amount']
    selected = [o for o in orders if statuses[o['order_status_id']] in ACCEPTED
                and payments_by_order.get(o['id'], {}).get('status') == 'completed']
    selected_ids = {r['id'] for r in selected}
    monthly = defaultdict(lambda: [0, Decimal(0), Decimal(0)])
    quarterly = defaultdict(lambda: [0, Decimal(0), Decimal(0)])
    for o in selected:
        dt = datetime.fromisoformat(o['created_at'])
        for key, groups in [(dt.strftime('%Y-%m'), monthly), (f'{dt.year}-Q{(dt.month-1)//3+1}', quarterly)]:
            groups[key][0] += 1
            groups[key][1] += o['subtotal'] - o['discount_amount']
            groups[key][2] += o['total']
    for name, groups in [('monthly_expected.csv', monthly), ('quarterly_expected.csv', quarterly)]:
        write_csv(name, ['Period', 'EligibleOrders', 'SalesValue', 'TotalBilled'],
                  [[period] + vals for period, vals in sorted(groups.items())])
    product = defaultdict(lambda: [0, Decimal(0), set()])
    for r in items:
        if r['order_id'] in selected_ids:
            vals = product[r['product_id']]
            vals[0] += r['quantity']
            vals[1] += r['quantity'] * r['unit_price']
            vals[2].add(r['order_id'])
    product_rows = [[pid, indexed['products'][pid]['name'], v[0], v[1], len(v[2])]
                    for pid, v in sorted(product.items(), key=lambda x: (-x[1][1], x[0]))]
    write_csv('products_expected.csv', ['ProductID', 'ProductName', 'UnitsSold', 'ItemGrossValue', 'OrderCount'], product_rows)
    customers = defaultdict(lambda: [0, Decimal(0)])
    for o in selected:
        customers[o['user_id']][0] += 1
        customers[o['user_id']][1] += o['subtotal'] - o['discount_amount']
    write_csv('customers_expected.csv', ['UserID', 'EligibleOrders', 'SalesValue'],
              [[uid] + v for uid, v in sorted(customers.items(), key=lambda x: (-x[1][1], x[0]))])
    issues = {
        'orders_without_items': sum(o['id'] not in {r['order_id'] for r in items} for o in orders),
        'eligible_orders_without_items': sum(o['id'] not in {r['order_id'] for r in items} for o in selected),
        'order_subtotal_vs_line_gross_mismatch': sum(o['subtotal'] != gross[o['id']] for o in orders),
        'order_tax_vs_line_tax_mismatch': sum(o['tax_amount'] != item_taxes[o['id']] for o in orders),
        'order_total_formula_mismatch': sum(o['total'] != o['subtotal'] - o['discount_amount'] + o['tax_amount'] + o['shipping_cost'] for o in orders),
        'payment_amount_vs_total_mismatch': sum(p['amount'] != indexed['orders'][p['order_id']]['total'] for p in payments),
        'payments_before_order': sum(p['processed_at'] < indexed['orders'][p['order_id']]['created_at'] for p in payments),
        'orders_before_user_created': sum(o['created_at'] < indexed['users'][o['user_id']]['created_at'] for o in orders),
        'completed_payment_on_cancelled_or_refunded_order': sum(p['status']=='completed' and statuses[indexed['orders'][p['order_id']]['order_status_id']] in {'cancelled','refunded'} for p in payments),
        'nonpositive_item_quantity': sum(r['quantity'] <= 0 for r in items),
        'negative_item_price': sum(r['unit_price'] < 0 for r in items),
        'nonzero_item_discount': sum(r['discount_amount'] != 0 for r in items),
        'return_quantity_exceeds_item_quantity': sum(r['quantity'] > indexed['order_items'][r['order_item_id']]['quantity'] for r in tables['order_returns']),
        'returns_requested_before_order': sum(r['requested_at'] < indexed['orders'][indexed['order_items'][r['order_item_id']]['order_id']]['created_at'] for r in tables['order_returns']),
    }
    totals = {'EligibleOrders': len(selected),
              'SalesValue': sum((o['subtotal']-o['discount_amount'] for o in selected), Decimal(0)),
              'TotalBilled': sum((o['total'] for o in selected), Decimal(0)),
              'ItemGrossValue': sum((gross[o['id']] for o in selected), Decimal(0)),
              'CustomersWithEligibleOrders': len(customers),
              'RepeatCustomers': sum(v[0]>=2 for v in customers.values())}
    assert totals['SalesValue'] == sum(v[1] for v in monthly.values()) == sum(v[1] for v in quarterly.values())
    assert totals['SalesValue'] == sum(v[1] for v in customers.values())
    assert totals['ItemGrossValue'] == sum(v[1] for v in product.values())
    assert not issues['order_total_formula_mismatch']
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    audit = {'source': 'data/source/' + SOURCE.name, 'sha256': source_hash,
             'source_notice': 'Synthetic sample data; CC0-1.0 per file header, not independently verified.',
             'execution': 'Independent Python parsing of SQL literals. SQL Server execution and reconciliation are recorded separately in outputs/sql_server/.',
             'table_counts': {t: len(rows) for t, rows in tables.items()},
             'foreign_keys_checked': len(foreign_keys), 'foreign_key_issues': fk_issues,
             'order_statuses': dict(Counter(statuses[o['order_status_id']] for o in orders)),
             'payment_statuses': dict(Counter(p['status'] for p in payments)),
             'date_min': min(o['created_at'] for o in orders),
             'date_max': max(o['created_at'] for o in orders),
             'quality_issues': issues, 'totals': totals,
             'checks': ['PK uniqueness', 'declared UNIQUE and NOT NULL', 'nvarchar UTF-16 length',
                        'all declared foreign keys', 'monthly=quarterly=customer sales totals',
                        'product gross=line gross on eligible orders'],
             'top_product': product_rows[0]}
    (PROJECT / 'outputs' / 'audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2, default=str), encoding='utf-8')
    write_csv('table_counts_expected.csv', ['TableName', 'ExpectedRows'], sorted(audit['table_counts'].items()))
    build_loader(text, tables)
    assert parse_dump((PROJECT / 'sql' / '01_tao_va_nap.sql').read_text(encoding='utf-8-sig')) == tables
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == source_hash
    print(json.dumps(audit, ensure_ascii=True, indent=2, default=str))


if __name__ == '__main__':
    main()
