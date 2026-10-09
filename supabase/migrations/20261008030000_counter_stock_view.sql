create or replace view public.v_counter_stock
with (security_invoker = true)
as
select cs.id,
       cs.counter_id,
       cs.stock_item_id,
       si.stock_order_id,
       si.inventory_id,
       si.units_per_quantity,
       i.name as inventory_name,
       i.barcode,
       i.description,
       l.id as listing_id,
       l.price,
       cs.quantity,
       cs.low_stock_threshold,
       cs.created_at,
       cs.updated_at,
       cs.counter_id as assigned_counter_id
from public.counter_stock as cs
join public.stock_items as si on si.id = cs.stock_item_id
join public.inventory as i on i.id = si.inventory_id
left join lateral (
  select l.id,
         l.price
  from public.listings as l
  where l.inventory_id = i.id
    and l.active = true
  order by l.created_at desc, l.id
  limit 1
) as l on true;
grant select on public.v_counter_stock to anon, authenticated;
