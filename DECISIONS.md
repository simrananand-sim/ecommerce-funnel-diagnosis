# Data cleaning decisions

Raw table `events_raw` is never edited. All analysis uses `events_clean`.

1. **Load:** 5 monthly CSVs loaded as-is into `events_raw` (20,692,840 rows).
   Oct 4,102,283 | Nov 4,635,837 | Dec 3,533,286 | Jan 4,264,752 | Feb 4,156,682.
   Session IDs checked: max length 36 (a wrong line terminator had added a hidden character).
2. **Timestamps:** stored as text with a " UTC" suffix. All 20,692,840 values were 23 characters (none malformed).
   Converted to DATETIME in `events_clean`. All times are UTC.
3. **category_code:** 98.3% empty. Not used. Category analysis uses `category_id` (500 IDs, no names).
4. **brand:** 42.3% empty. Used with a caveat (covers about 58% of rows).
5. **Negative prices (131 rows, 0.0006%):** all on 5 product_ids (5670257, 5716855, 5716857, 5716859, 5716861).
   126 are purchases (37 in Oct-Nov, 89 in Dec-Feb), plus 2 views and 3 removes. Cause unknown.
   Excluded from `events_clean`.
6. **Zero prices (104,157 rows, 0.5%):** price set to NULL, row kept (the behaviour is real),
   `price_was_zero = 1` added so the zeros can still be investigated.
   Only 1 of them is a purchase (Jan), so revenue is barely affected.
   Spike: zero-price carts were 1,207 in Dec and 1,672 in Jan, then 43,423 in Feb. To investigate before
   reading any February conversion change.
7. **Result:** `events_clean` = 20,692,709 rows (20,692,840 minus 131).
   Checked: NULL prices = flagged zeros = 104,157.
8. **Scale:** 1,639,358 users, 4,535,942 sessions (about 2.8 sessions per user).
9. **Funnel rule:** one order creates several purchase rows, so funnels count distinct sessions, not events.