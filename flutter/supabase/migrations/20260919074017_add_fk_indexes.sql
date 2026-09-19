create index if not exists idx_purchases_store_id on public.purchases(store_id);
create index if not exists idx_purchases_store_id_date on public.purchases(store_id, purchase_date);
create index if not exists idx_scan_events_purchase_id on public.scan_events(purchase_id);
create index if not exists idx_scan_events_store_id on public.scan_events(store_id);
create index if not exists idx_store_pins_store_id on public.store_pins(store_id);
create index if not exists idx_stores_owner_id on public.stores(owner_id);
