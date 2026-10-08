create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  role text not null check (role in ('OWNER', 'MANAGER')),
  created_at timestamptz not null default now()
);
create table public.counter_stations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.bartenders (
  id uuid primary key default gen_random_uuid(),
  counter_id uuid references public.counter_stations (id) on delete set null,
  name text not null,
  phone text not null unique,
  pin_hash text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.inventory (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  barcode text,
  description text,
  created_at timestamptz not null default now()
);
create unique index inventory_barcode_unique
  on public.inventory (barcode)
  where barcode is not null;
create table public.stock_orders (
  id uuid primary key default gen_random_uuid(),
  purchase_date timestamptz not null default now(),
  vendor_name text,
  created_at timestamptz not null default now()
);
create table public.stock_items (
  id uuid primary key default gen_random_uuid(),
  stock_order_id uuid not null references public.stock_orders (id) on delete cascade,
  inventory_id uuid not null references public.inventory (id),
  quantity numeric not null check (quantity > 0),
  units_per_quantity numeric not null check (units_per_quantity > 0),
  price numeric not null check (price >= 0),
  created_at timestamptz not null default now()
);
create table public.counter_stock (
  id uuid primary key default gen_random_uuid(),
  counter_id uuid not null references public.counter_stations (id) on delete cascade,
  stock_item_id uuid not null references public.stock_items (id) on delete cascade,
  quantity numeric not null check (quantity > 0),
  low_stock_threshold numeric not null default 1 check (low_stock_threshold >= 0),
  created_at timestamptz not null default now()
);
create unique index counter_stock_counter_item_unique
  on public.counter_stock (counter_id, stock_item_id);
create table public.listings (
  id uuid primary key default gen_random_uuid(),
  inventory_id uuid not null references public.inventory (id) on delete cascade,
  price numeric not null check (price >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index idx_unique_active_listing_per_inventory
  on public.listings (inventory_id)
  where active = true;
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  counter_id uuid references public.counter_stations (id) on delete set null,
  bartender_id uuid references public.bartenders (id) on delete set null,
  payment_type text check (payment_type in ('CASH', 'MOBILE_MONEY')),
  status text not null check (status in ('COMPLETED', 'VOIDED', 'HELD')),
  created_at timestamptz not null default now()
);
create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  stock_item_id uuid not null references public.stock_items (id) on delete restrict,
  listing_id uuid not null references public.listings (id) on delete restrict,
  units integer not null check (units > 0)
);
create index stock_items_inventory_id_idx on public.stock_items (inventory_id);
create index counter_stock_counter_id_idx on public.counter_stock (counter_id);
create index orders_created_at_idx on public.orders (created_at desc);
create index order_items_order_id_idx on public.order_items (order_id);
create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles as p
  where p.id = (select auth.uid())
$$;
revoke all on function public.current_app_role() from public, anon;
grant execute on function public.current_app_role() to authenticated;
alter table public.profiles enable row level security;
alter table public.counter_stations enable row level security;
alter table public.bartenders enable row level security;
alter table public.inventory enable row level security;
alter table public.stock_orders enable row level security;
alter table public.stock_items enable row level security;
alter table public.counter_stock enable row level security;
alter table public.listings enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
create policy "Management users read profiles"
  on public.profiles for select to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Owners and managers manage profiles"
  on public.profiles for all to authenticated
  using (
    (select public.current_app_role()) = 'OWNER'
    or id = (select auth.uid())
  )
  with check (
    (select public.current_app_role()) = 'OWNER'
    or (id = (select auth.uid()) and role = (select public.current_app_role()))
  );
create policy "Management users manage counters"
  on public.counter_stations for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage bartenders"
  on public.bartenders for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage inventory"
  on public.inventory for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage stock orders"
  on public.stock_orders for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage stock items"
  on public.stock_items for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage counter stock"
  on public.counter_stock for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users manage listings"
  on public.listings for all to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'))
  with check ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users read orders"
  on public.orders for select to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
create policy "Management users read order items"
  on public.order_items for select to authenticated
  using ((select public.current_app_role()) in ('OWNER', 'MANAGER'));
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.counter_stations to authenticated;
grant select, insert, update, delete on public.bartenders to authenticated;
grant select, insert, update, delete on public.inventory to authenticated;
grant select, insert, update, delete on public.stock_orders to authenticated;
grant select, insert, update, delete on public.stock_items to authenticated;
grant select, insert, update, delete on public.counter_stock to authenticated;
grant select, insert, update, delete on public.listings to authenticated;
grant select on public.orders, public.order_items to authenticated;
grant usage, select on all sequences in schema public to authenticated;
create or replace view public.v_inventory_stock_levels
with (security_invoker = true)
as
with received as (
  select si.inventory_id,
         sum(si.quantity * si.units_per_quantity) as total_received_units
  from public.stock_items as si
  group by si.inventory_id
), sold as (
  select si.inventory_id,
         sum(oi.units) as total_sold_units
  from public.order_items as oi
  join public.orders as o on o.id = oi.order_id and o.status = 'COMPLETED'
  join public.stock_items as si on si.id = oi.stock_item_id
  group by si.inventory_id
)
select i.id as inventory_id,
       i.name as item_name,
       i.barcode,
       coalesce(r.total_received_units, 0) as total_received_units,
       coalesce(s.total_sold_units, 0) as total_sold_units,
       coalesce(r.total_received_units, 0) - coalesce(s.total_sold_units, 0)
         as current_stock_units
from public.inventory as i
left join received as r on r.inventory_id = i.id
left join sold as s on s.inventory_id = i.id;
create or replace view public.v_counter_stock_allocations
with (security_invoker = true)
as
select cs.id as counter_stock_id,
       c.id as counter_id,
       c.name as counter_name,
       si.id as stock_item_id,
       i.id as inventory_id,
       i.name as inventory_name,
       i.barcode,
       greatest(
         cs.quantity - coalesce(sold.total_sold_units, 0) / si.units_per_quantity,
         0
       ) as quantity,
       si.units_per_quantity,
       cs.quantity * si.units_per_quantity as total_assigned_units,
       coalesce(sold.total_sold_units, 0) as total_sold_units,
       greatest(
         cs.quantity * si.units_per_quantity - coalesce(sold.total_sold_units, 0),
         0
       ) as remaining_units,
       cs.low_stock_threshold,
       cs.low_stock_threshold * si.units_per_quantity as low_stock_threshold_units,
       greatest(
         cs.quantity - coalesce(sold.total_sold_units, 0) / si.units_per_quantity,
         0
       ) <= cs.low_stock_threshold as is_low_stock,
       cs.created_at as assigned_at
from public.counter_stock as cs
join public.counter_stations as c on c.id = cs.counter_id
join public.stock_items as si on si.id = cs.stock_item_id
join public.inventory as i on i.id = si.inventory_id
left join lateral (
  select sum(oi.units) as total_sold_units
  from public.order_items as oi
  join public.orders as o on o.id = oi.order_id
  where oi.stock_item_id = si.id
    and o.counter_id = cs.counter_id
    and o.status = 'COMPLETED'
) as sold on true;
create or replace view public.v_stock_order_summaries
with (security_invoker = true)
as
select so.id as stock_order_id,
       so.purchase_date,
       so.vendor_name,
       count(si.id)::integer as total_items_count,
       coalesce(sum(si.quantity * si.units_per_quantity), 0) as total_units_received,
       coalesce(sum(si.price), 0) as total_order_cost
from public.stock_orders as so
left join public.stock_items as si on si.stock_order_id = so.id
group by so.id, so.purchase_date, so.vendor_name;
create or replace view public.v_order_summaries
with (security_invoker = true)
as
select o.id as order_id,
       o.counter_id,
       c.name as counter_name,
       o.bartender_id,
       b.name as bartender_name,
       o.payment_type,
       o.status,
       o.created_at,
       count(oi.id)::integer as total_items_count,
       coalesce(sum(oi.units * l.price), 0) as total_amount
from public.orders as o
left join public.counter_stations as c on c.id = o.counter_id
left join public.bartenders as b on b.id = o.bartender_id
left join public.order_items as oi on oi.order_id = o.id
left join public.listings as l on l.id = oi.listing_id
group by o.id, o.counter_id, c.name, o.bartender_id, b.name,
         o.payment_type, o.status, o.created_at;
create or replace view public.v_inventory_health
with (security_invoker = true)
as
select a.inventory_id,
       a.inventory_name as item_name,
       a.barcode,
       s.current_stock_units,
       a.counter_id,
       a.counter_name,
       a.quantity as counter_quantity,
       a.low_stock_threshold,
       a.is_low_stock
from public.v_counter_stock_allocations as a
join public.v_inventory_stock_levels as s on s.inventory_id = a.inventory_id;
create or replace view public.v_daily_sales_summary
with (security_invoker = true)
as
select date_trunc('day', s.created_at)::date as sale_date,
       coalesce(sum(s.total_amount) filter (where s.status = 'COMPLETED'), 0)
         as total_revenue,
       count(*) filter (where s.status = 'COMPLETED')::integer
         as completed_orders,
       coalesce(sum(s.total_amount) filter (
         where s.status = 'COMPLETED' and s.payment_type = 'CASH'
       ), 0) as cash_revenue,
       coalesce(sum(s.total_amount) filter (
         where s.status = 'COMPLETED' and s.payment_type = 'MOBILE_MONEY'
       ), 0) as mobile_money_revenue,
       coalesce(
         jsonb_object_agg(s.counter_name, s.counter_revenue)
           filter (where s.counter_name is not null),
         '{}'::jsonb
       ) as revenue_by_counter
from (
  select o.order_id,
         o.created_at,
         o.status,
         o.payment_type,
         o.counter_name,
         o.total_amount,
         sum(o.total_amount) filter (where o.status = 'COMPLETED')
           over (partition by date_trunc('day', o.created_at)::date, o.counter_name)
           as counter_revenue
  from public.v_order_summaries as o
) as s
group by date_trunc('day', s.created_at)::date;
create or replace view public.v_active_listings
with (security_invoker = true)
as
select l.id as listing_id,
       i.id as inventory_id,
       i.name as inventory_name,
       i.barcode,
       l.price,
       l.active,
       l.created_at
from public.listings as l
join public.inventory as i on i.id = l.inventory_id
where l.active = true;
grant select on public.v_inventory_stock_levels to authenticated;
grant select on public.v_counter_stock_allocations to authenticated;
grant select on public.v_stock_order_summaries to authenticated;
grant select on public.v_order_summaries to authenticated;
grant select on public.v_inventory_health to authenticated;
grant select on public.v_daily_sales_summary to authenticated;
grant select on public.v_active_listings to authenticated;
create or replace function public.set_active_listing(
  p_inventory_id uuid,
  p_price numeric,
  p_listing_id uuid default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result_id uuid;
begin
  if (select public.current_app_role()) not in ('OWNER', 'MANAGER') then
    raise exception 'Only owners and managers may manage listings';
  end if;
  if p_price < 0 then
    raise exception 'Listing price must be zero or greater';
  end if;

  update public.listings
     set active = false
   where inventory_id = p_inventory_id
     and active
     and (p_listing_id is null or id <> p_listing_id);

  if p_listing_id is null then
    insert into public.listings (inventory_id, price, active)
    values (p_inventory_id, p_price, true)
    returning id into result_id;
  else
    update public.listings
       set inventory_id = p_inventory_id, price = p_price, active = true
     where id = p_listing_id
    returning id into result_id;
    if result_id is null then
      raise exception 'Listing not found';
    end if;
  end if;
  return result_id;
end;
$$;
revoke all on function public.set_active_listing(uuid, numeric, uuid) from public, anon;
grant execute on function public.set_active_listing(uuid, numeric, uuid) to authenticated;
create or replace function public.create_bartender(
  p_name text,
  p_phone text,
  p_counter_id uuid,
  p_is_active boolean,
  p_pin text
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result_id uuid;
begin
  if (select public.current_app_role()) not in ('OWNER', 'MANAGER') then
    raise exception 'Only owners and managers may manage bartenders';
  end if;
  if p_pin !~ '^[0-9]{5,12}$' then
    raise exception 'PIN must contain 5 to 12 digits';
  end if;

  insert into public.bartenders (name, phone, counter_id, is_active, pin_hash)
  values (
    p_name,
    p_phone,
    p_counter_id,
    p_is_active,
    extensions.crypt(p_pin, extensions.gen_salt('bf'))
  )
  returning id into result_id;
  return result_id;
end;
$$;
create or replace function public.set_bartender_pin(
  p_bartender_id uuid,
  p_pin text
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select public.current_app_role()) not in ('OWNER', 'MANAGER') then
    raise exception 'Only owners and managers may manage bartenders';
  end if;
  if p_pin !~ '^[0-9]{5,12}$' then
    raise exception 'PIN must contain 5 to 12 digits';
  end if;

  update public.bartenders
     set pin_hash = extensions.crypt(p_pin, extensions.gen_salt('bf'))
   where id = p_bartender_id;
  if not found then
    raise exception 'Bartender not found';
  end if;
end;
$$;
revoke all on function public.create_bartender(text, text, uuid, boolean, text)
  from public, anon;
revoke all on function public.set_bartender_pin(uuid, text) from public, anon;
grant execute on function public.create_bartender(text, text, uuid, boolean, text)
  to authenticated;
grant execute on function public.set_bartender_pin(uuid, text) to authenticated;
create or replace function public.record_stock_purchase(
  p_vendor_name text,
  p_items jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  order_id uuid;
  line jsonb;
  line_inventory_id uuid;
  line_quantity numeric;
  line_units_per_quantity numeric;
  line_price numeric;
begin
  if (select public.current_app_role()) not in ('OWNER', 'MANAGER') then
    raise exception 'Only owners and managers may record stock purchases';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array' then
    raise exception 'A stock purchase must include at least one item';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'A stock purchase must include at least one item';
  end if;

  insert into public.stock_orders (vendor_name)
  values (nullif(trim(p_vendor_name), ''))
  returning id into order_id;

  for line in select value from jsonb_array_elements(p_items)
  loop
    line_inventory_id := (line->>'inventory_id')::uuid;
    line_quantity := (line->>'quantity')::numeric;
    line_units_per_quantity := (line->>'units_per_quantity')::numeric;
    line_price := (line->>'price')::numeric;
    if line_quantity <= 0 or line_units_per_quantity <= 0 or line_price < 0 then
      raise exception 'Quantity and units per package must be positive; price cannot be negative';
    end if;

    insert into public.stock_items (
      stock_order_id,
      inventory_id,
      quantity,
      units_per_quantity,
      price
    )
    values (
      order_id,
      line_inventory_id,
      line_quantity,
      line_units_per_quantity,
      line_price
    );
  end loop;

  return order_id;
end;
$$;
revoke all on function public.record_stock_purchase(text, jsonb)
  from public, anon;
grant execute on function public.record_stock_purchase(text, jsonb)
  to authenticated;
create or replace function public.allocate_stock_to_counter(
  p_counter_id uuid,
  p_stock_item_id uuid,
  p_quantity numeric,
  p_low_stock_threshold numeric
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  batch_quantity numeric;
  allocation_id uuid;
  total_allocated numeric;
begin
  if (select public.current_app_role()) not in ('OWNER', 'MANAGER') then
    raise exception 'Only owners and managers may allocate stock';
  end if;
  if p_quantity <= 0 or p_low_stock_threshold < 0 then
    raise exception 'Allocation quantity must be positive and threshold cannot be negative';
  end if;

  select si.quantity
    into batch_quantity
    from public.stock_items as si
   where si.id = p_stock_item_id
   for update;
  if not found then
    raise exception 'Stock batch not found';
  end if;

  select coalesce(sum(cs.quantity), 0)
    into total_allocated
    from public.counter_stock as cs
   where cs.stock_item_id = p_stock_item_id;

  if total_allocated + p_quantity > batch_quantity then
    raise exception 'Allocation exceeds the unassigned quantity in this stock batch';
  end if;

  insert into public.counter_stock (
    counter_id,
    stock_item_id,
    quantity,
    low_stock_threshold
  )
  values (p_counter_id, p_stock_item_id, p_quantity, p_low_stock_threshold)
  on conflict (counter_id, stock_item_id)
  do update set
    quantity = public.counter_stock.quantity + excluded.quantity,
    low_stock_threshold = excluded.low_stock_threshold
  returning id into allocation_id;
  return allocation_id;
end;
$$;
revoke all on function public.allocate_stock_to_counter(uuid, uuid, numeric, numeric)
  from public, anon;
grant execute on function public.allocate_stock_to_counter(uuid, uuid, numeric, numeric)
  to authenticated;
