---
name: x-browser-human
description: Control X/Twitter via browser in a human-like way — scroll feed, like, repost, reply, and post based on trending topics with randomized timing so the activity is indistinguishable from a person. Use when asked to "engage on X like a human", "browse Twitter", "check trending and interact", "reply to tweets", "act as me on X", or "use the browser on Twitter". Always prefer this over the Twitter API for engagement actions.
---

# X/Twitter Browser Engagement — Human Mode

BabaChef controls X.com through Chrome using CDP (Chrome DevTools Protocol) to browse, engage, and post as Shane. Every action includes human-like delays and natural behavior patterns so X cannot distinguish this from a real person using the site.

---

## Browser Profile to Use

Always use the **`openclaw` profile** (Chrome on port 18800). This is an isolated Chrome managed by OpenClaw that Shane logs into X with. If X is not logged in, navigate to `https://x.com` and check — if it shows the landing page instead of Home feed, call out that Shane needs to log in manually first.

---

## Step 0 — Orient in the Browser

```
list_pages
```

Look for a page with `x.com` in the URL. If one exists:
```
select_page(pageId=<the x.com page ID>, bringToFront=true)
```

If no X tab is open:
```
navigate_page(type="url", url="https://x.com/home")
```

Then wait 3-5 seconds (simulate page load + reading delay) before taking any action.

---

## Step 1 — Check What's Trending on X

After landing on home:

```
navigate_page(type="url", url="https://x.com/explore/tabs/trending")
```

Wait 4 seconds. Take a snapshot:
```
take_snapshot
```

Read the trending topics list. Pick **2 topics** that align with today's BabaChef persona (check SOUL.md for today's persona via `day_of_year % 11`). For tech/engineering topics prefer the top 5 trending in Technology if visible.

**Also cross-check with web_fetch sources:**
- `https://news.ycombinator.com` — HN front page for deeper tech signal
- `https://trends.google.com/trending?geo=US&category=5` — Tech search trends

Pick your 2 topics before starting engagement. Log them to memory:
```
append ~/.openclaw/workspace-babachef/memory/browser-session.md
"[Date] Topics: {topic1}, {topic2}"
```

---

## Step 2 — Warm Up (Feed Scroll)

**NEVER start liking/replying immediately.** Humans scroll first.

```
navigate_page(type="url", url="https://x.com/home")
```

Then do a **warm-up scroll** for 60-90 seconds:

```javascript
// Scroll naturally — use evaluate_script
evaluate_script(`
  (async () => {
    const delay = ms => new Promise(r => setTimeout(r, ms));
    for (let i = 0; i < 8; i++) {
      window.scrollBy(0, Math.floor(Math.random() * 300 + 200));
      await delay(Math.random() * 3000 + 2000);
    }
  })();
`)
```

After scrolling, take a snapshot to see what's in the feed. This is "reading time" — the agent processes what's visible before deciding what to engage with.

---

## Step 3 — Engagement Actions

### Timing Rules (CRITICAL — do not skip)

| Action | Wait Before | Wait After |
|--------|-------------|------------|
| Like a tweet | 8–25 seconds | 5–15 seconds |
| Repost | 20–45 seconds | 15–30 seconds |
| Reply | 40–90 seconds (compose time) | 30–60 seconds |
| Search for topic | 5–10 seconds | 8–15 seconds |
| Navigate to new page | 3–8 seconds | 4–10 seconds |

**Between action batches (every 3-5 actions): pause 3-8 minutes.**

To implement delays within the browser session:
```javascript
evaluate_script(`
  new Promise(r => setTimeout(r, ${Math.floor(Math.random() * 15000 + 8000)}))
`)
```

Or use `wait_for` to wait for elements to exist as a natural pause.

---

### Like a Tweet

1. Find a tweet in the snapshot that's relevant to today's topic
2. Wait 8-25 seconds (random — "reading" the tweet)
3. Click the like button (heart icon, `aria-label` containing "Like"):
```
click('[data-testid="like"]')
```
4. Wait 5-15 seconds before next action

**Skip liking if:**
- The tweet is political (not tech/engineering adjacent)
- The tweet has less than 20 likes (too obscure, unusual for a person to see it)
- You've already liked 3 consecutive tweets from the same person

---

### Repost (Retweet)

1. Wait 20-45 seconds
2. Click the repost button:
```
click('[data-testid="retweet"]')
```
3. In the menu that appears, click "Repost" (not Quote):
```
click('[data-testid="retweetConfirm"]')
```
4. Wait 15-30 seconds

---

### Reply to a Tweet

This is the most human-feeling action — takes the most "thought time."

1. Click the reply button:
```
click('[data-testid="reply"]')
```
2. Wait 15-30 seconds (simulating "thinking about what to say")
3. Get the compose box snapshot to confirm it's open
4. Generate the reply using BabaChef's voice (see Voice Rules below)
5. Type the reply with realistic pacing:
```javascript
evaluate_script(`
  (async () => {
    const delay = ms => new Promise(r => setTimeout(r, ms));
    const text = "${reply_text}";
    const el = document.querySelector('[data-testid="tweetTextarea_0"]');
    el.focus();
    for (const ch of text) {
      el.dispatchEvent(new InputEvent('input', {data: ch, bubbles: true}));
      await delay(Math.random() * 80 + 40); // 40-120ms per character
    }
  })()
`)
```
6. Wait 10-20 seconds after typing (review pause)
7. Click reply submit:
```
click('[data-testid="tweetButton"]')
```
8. Wait 30-60 seconds after posting

---

### Search for Trending Topic

```
navigate_page(type="url", url="https://x.com/search?q={encoded_topic}&src=trend_click&vertical=trends")
```

Wait 5 seconds. Take snapshot. Scroll through results using `evaluate_script` scroll. Find 3-5 relevant tweets to engage with.

---

## Step 4 — Post Original Content (Based on Trends)

After engaging with the trend, post an original tweet if appropriate.

1. Navigate home:
```
navigate_page(type="url", url="https://x.com/home")
```
2. Wait 30-60 seconds (transition time)
3. Click the compose box:
```
click('[data-testid="tweetTextarea_0"]')
```
4. Type the tweet (generated by BabaChef using today's persona + trending topic):
```
type_text("{generated_tweet_text}")
```
5. Wait 15-30 seconds (review pause)
6. Take a screenshot to confirm the tweet looks right:
```
take_screenshot
```
7. Click post:
```
click('[data-testid="tweetButton"]')
```
8. Wait 20-40 seconds

**Voice rules for original posts:**
- Lowercase, dry, punchy — max 240 chars
- Riff on the trend without announcing you saw it trending
- Sounds like a thought you had, not content you scheduled
- No "hot take:" or "unpopular opinion:" openers
- See SOUL.md for full voice guide

---

## Step 5 — Reply Voice Rules

- Max 200 characters
- No "great point!" or "love this!" openers — ever
- No question hooks ("Have you tried...?")
- Dry, lowercase, one observation max
- Feels like a passing thought that escaped
- Examples:
  - `had the same production incident at 2am. the root cause was hubris.`
  - `kubernetes disagrees with your assumptions here.`
  - `this is what happens when you write it down before shipping.`

---

## Daily Action Budgets (conservative — stay well under X limits)

| Action | Daily Max | Session Max (per run) |
|--------|-----------|----------------------|
| Likes | 40 | 8 |
| Reposts | 8 | 3 |
| Replies | 12 | 4 |
| Original Posts | 5 | 2 |

**Track in memory:**
```bash
# After each session, append action counts to daily log
echo "[$(date)] likes:X reposts:X replies:X posts:X" >> ~/.openclaw/workspace-babachef/memory/x-actions.log
```

---

## Session Pattern (Full Engagement Cycle)

Run this pattern for a single "session" (20-35 minutes of activity):

```
1. [0:00] Navigate to X, warm-up scroll (60-90s)
2. [1:30] Check trending — pick 2 topics
3. [3:00] Search topic #1 — engage with 2-3 tweets (like/reply)
4. [8:00] Pause 5-8 minutes (do nothing — "walked away")
5. [15:00] Return to home feed — scroll, like 2-3 more tweets
6. [20:00] Post 1 original tweet on trending topic
7. [22:00] Search topic #2 — engage with 1-2 tweets (no more replying)
8. [28:00] End session — log actions
```

---

## Error Handling

| Issue | Action |
|-------|--------|
| `take_snapshot` shows login page | Stop. Tell user: "X is not logged into the openclaw browser. Please log in at x.com manually in that Chrome window." |
| Tweet compose box doesn't open | Try `navigate_page(type="reload")` then retry once |
| Like button disabled / grayed | Skip that tweet — you may have already liked it |
| Rate limit banner appears on X | Stop immediately. Wait 15 minutes. Log to x-actions.log |
| Any "unusual activity" or captcha | Stop all browser actions immediately. Report to user. |

---

## Check Before Every Session

```bash
# Check today's action log — don't exceed daily limits
cat ~/.openclaw/workspace-babachef/memory/x-actions.log | grep "$(date +%Y-%m-%d)"
```

If daily limits already hit, do not engage. Report to user.
