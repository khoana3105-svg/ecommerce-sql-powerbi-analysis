"""Compare actual SQL Server result exports with independent Python expectations."""
from pathlib import Path
from decimal import Decimal
import csv
import hashlib
import json

PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT / 'outputs'
LIVE = OUT / 'sql_server'


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def main():
    execution = json.loads((LIVE / 'execution.json').read_text(encoding='utf-8-sig'))
    audit = json.loads((OUT / 'audit.json').read_text(encoding='utf-8'))
    results = {}
    for info in execution['ResultSets']:
        rows = read_csv(LIVE / info['File'])
        assert len(rows) == info['Rows'], info['File']
        results[tuple(info['Columns'])] = rows

    def find(first_column):
        matches = [v for k, v in results.items() if k[0] == first_column]
        assert len(matches) == 1, first_column
        return matches[0]

    checks = []
    assert execution['SourceTablesChecked'] == 31
    assert execution['ForeignKeys'] == 36 and execution['DisabledOrUntrustedForeignKeys'] == 0
    checks.append('31 source table counts and 36 enabled/trusted foreign keys')
    overall = next(v for k, v in results.items() if 'DistinctEligibleOrders' in k)[0]
    for field in ['EligibleOrders', 'ItemGrossValue', 'SalesValue', 'TotalBilled', 'CustomersWithEligibleOrders']:
        assert Decimal(overall[field]) == Decimal(str(audit['totals'][field])), field
    assert overall['EligibleOrders'] == overall['DistinctEligibleOrders']
    checks.append('order-level totals and view uniqueness')

    for filename, period_column in [('monthly_expected.csv', 'SalesMonth'), ('quarterly_expected.csv', 'SalesQuarter')]:
        actual_rows = next(v for k, v in results.items() if period_column in k)
        actual = {}
        for r in actual_rows:
            suffix = f"{int(r[period_column]):02d}" if period_column == 'SalesMonth' else f"Q{r[period_column]}"
            actual[f"{r['SalesYear']}-{suffix}"] = r
        expected = read_csv(OUT / filename)
        assert len(actual) == len(expected)
        for r in expected:
            for field in ['EligibleOrders', 'SalesValue', 'TotalBilled']:
                assert Decimal(actual[r['Period']][field]) == Decimal(r[field]), (r['Period'], field)
        checks.append(f'{len(expected)} periods match {filename}')

    products = next(v for k, v in results.items() if 'ProductID' in k and 'OrderCount' in k)
    for actual, expected in zip(products, read_csv(OUT / 'products_expected.csv')[:10]):
        assert actual['ProductName'] == expected['ProductName']
        for field in ['ProductID', 'UnitsSold', 'ItemGrossValue', 'OrderCount']:
            assert Decimal(actual[field]) == Decimal(expected[field]), field
    customers = next(v for k, v in results.items() if 'FirstEligibleOrderDate' in k)
    for actual, expected in zip(customers, read_csv(OUT / 'customers_expected.csv')[:10]):
        for field in ['UserID', 'EligibleOrders', 'SalesValue']:
            assert Decimal(actual[field]) == Decimal(expected[field]), field
    checks.append('top 10 products and top 10 customers match independent expectations')
    assert len(results[('UserID',)]) == 4
    repeat = find('PurchasingCustomers')[0]
    assert int(repeat['PurchasingCustomers']) == 66 and int(repeat['RepeatCustomers']) == 56
    checks.append('repeat customers and accounts without eligible orders')
    for column, expected in [('TotalFormulaMismatch', 0), ('PaymentAmountMismatch', 0),
                             ('OrdersBeforeUserCreated', 108), ('CompletedPaymentOnCancelledOrRefunded', 56),
                             ('OrdersWithoutPayment', 10), ('OrdersWithoutItems', 22)]:
        assert int(find(column)[0][column]) == expected, column
    assert next(v for k, v in results.items() if k == ('id', 'subtotal', 'ItemGross', 'tax_amount', 'ItemTax')) == []
    checks.append('EDA counts and order-to-item amount reconciliation')
    for column, expected in [('CorrectTotalBilled', '70317.71'), ('ItemGrossFromLines', '61632.94'),
                             ('ItemGrossFromOrders', '61632.94')]:
        assert Decimal(find(column)[0][column]) == Decimal(expected)
    assert Decimal(find('RepeatedTotalAfterItemJoin_DoNotUse')[0]['RepeatedTotalAfterItemJoin_DoNotUse']) != Decimal('70317.71')
    checks.append('JOIN multiplication demonstration differs from correct total')
    source = PROJECT / audit['source']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == audit['sha256']
    hashes = {str(p.relative_to(PROJECT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted((PROJECT / 'sql').glob('*.sql'))}
    report = {'status': 'passed', 'database': execution['Database'],
              'sql_server_version': execution['SqlServerVersion'],
              'executed_at_utc': execution['VerifiedAtUTC'], 'result_sets': len(results),
              'checks': checks, 'source_sha256': audit['sha256'], 'sql_sha256': hashes,
              'remaining_runtime_gaps': []}
    (LIVE / 'verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
