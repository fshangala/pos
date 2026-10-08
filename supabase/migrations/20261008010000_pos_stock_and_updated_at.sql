alter table public.profiles
  add column updated_at timestamptz not null default now();
alter table public.counter_stations
  add column updated_at timestamptz not null default now();
alter table public.bartenders
  add column updated_at timestamptz not null default now();
alter table public.inventory
  add column updated_at timestamptz not null default now();
alter table public.stock_orders
  add column updated_at timestamptz not null default now();
alter table public.stock_items
  add column updated_at timestamptz not null default now();
alter table public.counter_stock
  add column updated_at timestamptz not null default now();
alter table public.listings
  add column updated_at timestamptz not null default now();
alter table public.orders
  add column updated_at timestamptz not null default now();
alter table public.order_items
  add column updated_at timestamptz not null default now();
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger set_counter_stations_updated_at
  before update on public.counter_stations
  for each row execute function public.set_updated_at();
create trigger set_bartenders_updated_at
  before update on public.bartenders
  for each row execute function public.set_updated_at();
create trigger set_inventory_updated_at
  before update on public.inventory
  for each row execute function public.set_updated_at();
create trigger set_stock_orders_updated_at
  before update on public.stock_orders
  for each row execute function public.set_updated_at();
create trigger set_stock_items_updated_at
  before update on public.stock_items
  for each row execute function public.set_updated_at();
create trigger set_counter_stock_updated_at
  before update on public.counter_stock
  for each row execute function public.set_updated_at();
create trigger set_listings_updated_at
  before update on public.listings
  for each row execute function public.set_updated_at();
create trigger set_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();
create trigger set_order_items_updated_at
  before update on public.order_items
  for each row execute function public.set_updated_at();
create or replace view public.v_pos_counter_sellable_stock
with (security_invoker = true)
as
select cs.id as counter_stock_id,
       c.id as counter_id,
       c.name as counter_name,
       si.id as stock_item_id,
       i.id as inventory_id,
       i.name as item_name,
       i.description,
       i.barcode,
       l.id as listing_id,
       l.price,
       cs.quantity as allocated_quantity,
       si.units_per_quantity,
       cs.quantity * si.units_per_quantity as allocated_units,
       c.updated_at as counter_updated_at,
       cs.updated_at as allocation_updated_at,
       si.updated_at as stock_item_updated_at,
       i.updated_at as inventory_updated_at,
       l.updated_at as listing_updated_at
from public.counter_stock as cs
join public.counter_stations as c on c.id = cs.counter_id
join public.stock_items as si on si.id = cs.stock_item_id
join public.inventory as i on i.id = si.inventory_id
join public.listings as l
  on l.inventory_id = i.id
 and l.active
where c.is_active;
