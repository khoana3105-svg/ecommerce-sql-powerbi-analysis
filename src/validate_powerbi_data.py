"""Validate the actual SQL exports; build a date dimension using stdlib only."""
from pathlib import Path
from collections import Counter
from datetime import date, timedelta
from decimal import Decimal
import csv
import json
import hashlib

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'powerbi/data'


def read(name):
    with (DATA / f'{name}.csv').open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def main():
    orders, items, products, customers = [read(n) for n in ['FactOrders', 'FactOrderItems', 'DimProducts', 'DimCustomers']]
    for rows, key in [(orders, 'OrderID'), (items, 'OrderItemID'), (products, 'ProductID'), (customers, 'UserID')]:
        assert len(rows) == len({r[key] for r in rows}), key
    assert len(orders) == 250 and len(items) == 696
    order_ids, product_ids, customer_ids = [{r[k] for r in rows} for rows,k in [(orders,'OrderID'),(products,'ProductID'),(customers,'UserID')]]
    assert all(r['OrderID'] in order_ids and r['ProductID'] in product_ids for r in items)
    assert all(r['UserID'] in customer_ids for r in orders)
    sales = sum(Decimal(r['SalesValue']) for r in orders)
    total = sum(Decimal(r['TotalBilled']) for r in orders)
    gross = sum(Decimal(r['ItemGrossValue']) for r in items)
    assert sales == Decimal('61041.13') and total == Decimal('70317.71')
    assert gross == Decimal('61632.94') == sum(Decimal(r['ItemGrossValue']) for r in orders)
    counts = Counter(r['UserID'] for r in orders)
    repeats = sum(n >= 2 for n in counts.values())
    assert len(counts) == 66 and repeats == 56
    start = date(min(date.fromisoformat(r['OrderDate']).year for r in orders), 1, 1)
    end = date(max(date.fromisoformat(r['OrderDate']).year for r in orders), 12, 31)
    with (DATA / 'DimDate.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Date','Year','Quarter','MonthNumber','YearMonth','YearMonthSort'])
        current = start
        while current <= end:
            writer.writerow([current.isoformat(),current.year,(current.month-1)//3+1,current.month,current.strftime('%Y-%m'),current.year*100+current.month])
            current += timedelta(days=1)
    report = {
        'status':'passed', 'data_kind':'synthetic supplied SQL sample',
        'population':'paid/shipped/delivered orders with completed payment; order-date period',
        'counts':{'FactOrders':len(orders),'FactOrderItems':len(items),'DimProducts':len(products),'DimCustomers':len(customers)},
        'unfiltered_expected':{'Orders':len(orders),'SalesValue':str(sales),'TotalBilled':str(total),
            'ItemGrossValue':str(gross),'PurchasingCustomers':len(counts),'RepeatCustomers':repeats,
            'AverageOrderValue':str(sales/len(orders)), 'RepeatCustomerPct':str(Decimal(repeats)/len(counts)*100)},
        'csv_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(DATA.glob('*.csv'))},
        'powerbi_desktop_execution':'Not run; these checks validate CSV inputs and expected measures, not a PBIX.'
    }
    (ROOT / 'powerbi/validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report['unfiltered_expected'],indent=2))


if __name__ == '__main__':
    main()
