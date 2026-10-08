grant usage on schema public to anon;
revoke all privileges on all tables in schema public from anon;
grant select on all tables in schema public to anon;
create policy "Anonymous users read profiles"
  on public.profiles for select to anon using (true);
create policy "Anonymous users read counters"
  on public.counter_stations for select to anon using (true);
create policy "Anonymous users read bartenders"
  on public.bartenders for select to anon using (true);
create policy "Anonymous users read inventory"
  on public.inventory for select to anon using (true);
create policy "Anonymous users read stock orders"
  on public.stock_orders for select to anon using (true);
create policy "Anonymous users read stock items"
  on public.stock_items for select to anon using (true);
create policy "Anonymous users read counter stock"
  on public.counter_stock for select to anon using (true);
create policy "Anonymous users read listings"
  on public.listings for select to anon using (true);
create policy "Anonymous users read orders"
  on public.orders for select to anon using (true);
create policy "Anonymous users read order items"
  on public.order_items for select to anon using (true);
