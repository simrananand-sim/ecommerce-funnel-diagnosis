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
10. Duplicates (same session, second, event type, product): 1,045,756 groups, 1,109,092 extra rows (5.4%).
    89% are remove_from_cart (about 25% of removes in EVERY month, Oct 24.2% to Feb 25.8%), 10% cart (1.7-2.6%),
    purchase 898 and view 1,031. Cause unverified (double-logging vs real repeats; no quantity column).
    Not deleted. Funnel counts distinct sessions, so it is unaffected.
    Row-count metrics (remove rate) are reported raw and de-duplicated.
    Remove/cart ratio still rises about 6 points from Oct to Nov after removing extras, so that jump is not a duplicate artifact.
11. Session funnel (all 5 months, 4,535,941 sessions): view 4,280,700 | cart 985,781 | purchase 155,617.
    Session conversion 3.43% (about 28:1, in line with published analyses of this dataset).
    Not strictly sequential: 20.0% of cart sessions have no view, 25.2% of purchase sessions have no view,
    18.8% of purchase sessions have no cart. Cause unverified (possibly a view or cart in an earlier session).
12. Session conversion by month: Oct 3.40% | Nov 3.86% | Dec 3.42% | Jan 3.33% | Feb 3.14%.
    The Dec "drop" in event counts was partly fewer sessions (-11%); at session level Dec is flat vs Oct.
    Nov is the outlier. Day-level (15 Nov-5 Dec): two peaks (21-24 Nov 4.80%, 28-30 Nov 4.55%) around a trough
    (25-27 Nov 2.82%). Black Friday (29 Nov) is not a single spike, so not used as a pre/post test.
    No promotion data available; cause unverified.
13. sessions_summary built (4,535,941 sessions, 155,617 with a purchase; matches the funnel).
    273 sessions (0.006%) contain more than one user_id. Kept; each is assigned to its lowest user_id.
    Funnel metrics unaffected; user-level analysis carries this tiny caveat.    
14. user_first built (1,638,877 users, first 2019-10-01 00:00:00, last 2020-02-29 23:57:23).
    481 user_ids (0.03%) appear only inside multi-user sessions, so they have no row; their activity
    is counted under the lowest user_id of each session. No sessions are lost (join reconciles exactly
    to the monthly totals).
15. New vs returning: a session is "new" if it starts at the user's first-ever session time.
    1,980 sessions (0.04%) are ties (two sessions in the same second) and count as new.
    October labels are unreliable (data starts 1 Oct, so earlier customers look new); comparisons
    start from November.
    Nov to Feb: both groups decline (new 2.76% to 1.95%, returning 4.41% to 3.70%); the new share is
    flat (33.4% to 32.4%), so the slide is not a mix effect. Cause unverified; no traffic-source data.
