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
   Spike: zero-price carts were 1,207 in Dec and 1,672 in Jan, then 43,423 in Feb. 
   Investigated: the zero-price carts sit in 4,415 sessions (0.1% of all sessions). Excluding them changes monthly conversion by at most 0.02 points (Feb 3.13% either way), so they do not explain February’s decline. The Feb event spike came from under 2,000 sessions repeating the event. Cause unverified.
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
12. Session conversion by month: Oct 3.40% | Nov 3.86% | Dec 3.42% | Jan 3.33% | Feb 3.13%.
    The Dec "drop" in event counts was partly fewer sessions (-11%); at session level Dec is flat vs Oct.
    Nov is the outlier. Day-level (15 Nov-5 Dec): two peaks (21-24 Nov average 4.80%, up to 5.4% on the best day;
    28-30 Nov average 4.55%, up to 4.8%) around a trough (25-27 Nov average 2.82%). Black Friday (29 Nov) is not
    a single spike, so not used as a pre/post test.
    No promotion data available; cause unverified.
13. sessions_summary built (4,535,941 sessions, 155,617 with a purchase; matches the funnel).
    273 sessions (0.006%) contain more than one user_id. Kept; each is assigned to its lowest user_id.
    Funnel metrics unaffected; user-level analysis carries this tiny caveat.    
14. user_first built (1,638,877 users, first 2019-10-01 00:00:00, last 2020-02-29 23:57:23).
    481 user_ids (0.03%) most likely appear only inside multi-user sessions, so they have no row; their activity
    is counted under the lowest user_id of each session. No sessions are lost (join reconciles exactly
    to the monthly totals).
15. New vs returning: a session is "new" if it starts at the user's first-ever session time.
    1,980 sessions (0.04%) are ties (two sessions in the same second) and count as new.
    October labels are unreliable (data starts 1 Oct, so earlier customers look new); comparisons
    start from November.
    the new share was flat from Nov to Feb (33.4% to 32.4%), and fell from 35.8% to 32.4% from Dec to Feb, 
    which would have raised conversion, so mix does not explain the slide.
16. October "new" labels are contaminated: the new-session cart rate falls from 47.7% (week of 1 Oct) to
    28.8% (7 Oct) and 18.2% (14 Oct), then stays at about 17-19% through November. Customers who shopped
    before 1 Oct look new until they return. Rule: new vs returning is read only from 14 Oct onward;
    the overall "Oct cart rate 26.2%" is not used as a baseline. Weekly new-session totals reconcile to
    the monthly new totals (713,633 for Oct+Nov).
    New-user conversion is flat Oct to Nov (about 2.55-2.9% by week). Cause of the inflated early-October
    carts (conversion unchanged) unverified.
17. Weekly new vs returning (14 Oct to 29 Feb). Weekly new-session totals match the earlier
    runs for the weeks both cover; the week of 25 Nov differs only because an earlier run stopped at 30 Nov.
    New-user conversion falls from about 2.66% (14 Oct to 25 Nov, excluding the week of 18 Nov)
    to about 2.33% (December) to about 2.05% (6 Jan to 24 Feb). The new-user cart rate steps
    down from about 17.8% (week of 25 Nov) to 15.2% (week of 2 Dec) and stays at 13-15.5%.
    Returning conversion changes little (about 4.1% to 3.85%).
    The week of 18 Nov is a traffic surge (175k returning sessions vs about 125k).
    The week of 30 Dec is a holiday week with the lowest new conversion (1.51%).
    The cause of the December step is unverified (no traffic-source or promotion data).
    Weekly averages are simple, not session-weighted.
18. Daily new-user conversion, 18 Nov to 11 Dec: baseline 2.56-2.61% (18-20 Nov), peak 1 on 21-24 Nov
    (up to 4.19% on 22 Nov), trough 25-27 Nov (2.08-2.14%), peak 2 on 28-30 Nov (up to 3.85%),
    then 1.91-2.57% through 11 Dec. The shift down starts on 25 Nov, not in December; the weekly view
    hid this because the week of 25 Nov mixes trough and peak-2 days. Cause unverified (no promotion
    or traffic-source data); reported as descriptive. New-user conversion is about 2.6% before
    and about 2.2-2.3% after.
19. Cart-to-purchase is measured within a single session. A shopper who saves a cart and buys in a later 
    session counts as a drop-off, so within-session cart-to-purchase understates true completion.
    Not tested.