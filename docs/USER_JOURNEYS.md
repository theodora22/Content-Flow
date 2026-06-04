# User Journeys — Plan & Issue Set

> Source of truth for wiring the two core user journeys end-to-end. Written before the
> GitHub issues are created so the plan survives independently of the board. Keep this
> doc and the created issues in sync.

## The two journeys

1. **First-run:** Sign Up → Creator Profile → Create First Idea → Create First Script → Create First LinkedIn Post → Dashboard.
2. **Returning:** Sign In → Dashboard → New Idea → New Script → New LinkedIn Post.

## Current state (verified)

- **Auth (Devise):** sign up + sign in work. `ApplicationController` gates everything with `authenticate_user!`; `pages#home` is the only public action.
- **Models + tables all exist:** `Creator(name,topic,goal,audience,user_id)`, `Idea(title,description,topic,user_id)`, `Script(title,description,style,length,system_prompt,idea_id)`, `LinkedinPost(title,hook,body,script_id)`, plus `GeneratedIdea` and the ruby_llm `Chat/Message/Model`.
- **Creator form** (`new`/`edit`) built; `show` empty; `creator_params` bug (`require(:creators)` → should be `:creator`).
- **Empty shells:** `IdeasController`, `ScriptsController`, `LinkedinPostsController`, `GeneratedIdeasController` — no actions; views are empty stubs.
- **Missing entirely:** dashboard, navigation, post-signup redirect logic, links between steps.
- **Chat has no owner:** `chats` table has only `model_id`.

## Gap analysis

| Journey step | Model | Table | Controller | Views | Gap |
|---|---|---|---|---|---|
| Sign up / in | User (Devise) | ✓ | built-in | ✓ | none — add post-auth redirect |
| Creator profile | ✓ | ✓ | partial | new/edit only | show + param fix + redirect |
| Idea | ✓ | ✓ | empty | empty | full CRUD + views |
| Script | ✓ | ✓ | empty | empty | full CRUD (nested/shallow) |
| LinkedIn post | ✓ | ✓ | empty | empty | full CRUD (singular nested) |
| Dashboard | — | — | none | none | new controller + view |
| Navigation | — | — | — | none | nav partial |
| Chat ownership | Chat | partial | ✓ | ✓ | polymorphic `chattable` |
| Creator-aware LLM | — | — | — | — | system-instruction context |

## Design decisions

1. **Post-auth routing** — override `after_sign_in_path_for` / `after_sign_up_path_for` in `ApplicationController`. Single branch: `creator.present? ? dashboard_path : new_creator_path`. No global `before_action` wizard lock.
2. **Onboarding state** — derived from data (no flag). `User#onboarding_complete?`, `User#next_onboarding_step` (`:creator|:idea|:script|:post|:done`).
3. **Dashboard** — new `DashboardController#show`; keep `pages#home` public (redirect to dashboard when signed in).
4. **Polymorphic chat** — add `chattable_type`/`chattable_id` to `chats`; `Chat belongs_to :chattable, polymorphic: true, optional: true`; content models `has_many :chats, as: :chattable`. **Owners: `User`, `Idea`, `Script`, `LinkedinPost` (all `has_many`). `Creator` owns no chats** — since `User has_one :creator` (1:1), top-level chats live on the `User` to avoid a redundant User/Creator overlap; `LlmContext` reaches brand context via `user.creator`. (Supersedes #47's literal `has_one` on Creator.)
5. **Cascading LLM context** — `LlmContext.for(chattable)` walks the ancestry chain (`LinkedinPost → Script → Idea → User → Creator`) and builds a layered system prompt; applied via `chat.with_instructions(...)` at chat creation. Verified ruby_llm v1.15.0 `with_instructions` persists a `role: :system` message.
6. **Structured generation** — `RubyLLM::Schema` subclasses (`IdeaSchema/ScriptSchema/LinkedinPostSchema`) on the generation path via `with_schema`.
7. **Guided but skippable** — only the creator-profile branch is enforced; everything else is CTAs/redirects.
8. **Authorization** — scripts/posts have no `user_id`; ownership runs through `idea.user`.

## Issue set

All issues: repo `theodora22/Content-Flow`, assignee `theodora22`, project #4 "Project - Content Flow", **Status = Backlog**. Sequencing: A1→A2→A3 → B1 → C1 → D1 → E1 → (F1→F2→F3→F4) → G1; H1 alongside D1/E1.

### EPIC A — App Shell & Journey Routing
- **A1 — Layout shell + global navigation.** `app/views/shared/_nav.html.erb` (authed nav + sign-out `button_to destroy_user_session_path, method: :delete`; login/signup when logged out); render in `app/views/layouts/application.html.erb`.
- **A2 — Public landing vs authed dashboard split.** New `DashboardController#show` (placeholder), `app/views/dashboard/show.html.erb`, route `get "dashboard"`; `pages#home` redirect when signed in; real landing in `app/views/pages/home.html.erb`. *(Reconcile #5.)* Depends on nothing hard; precedes A3.
- **A3 — Post-auth routing + onboarding state.** `ApplicationController#after_sign_in_path_for`/`after_sign_up_path_for`; `User` gets `has_many :ideas, dependent: :destroy`, `onboarding_complete?`, `next_onboarding_step`. Depends on A2.

### EPIC B — Creator Profile
- **B1 — Finish Creator profile.** Implement `CreatorsController#show`; fill `creators/show.html.erb`; fix `creator_params` (`:creators`→`:creator`); post-create redirect into onboarding. *(Supersedes #8; keep #4 fields, #7 preview as design follow-ups.)* Depends on A3.

### EPIC C — Ideas CRUD
- **C1 — IdeasController full CRUD + views** scoped to `current_user.ideas`. Fill `index`/`show`; create `new`/`edit`/`_form`/`_idea`. Show lists scripts + "Write a script" CTA. *(Distinct from AI idea feed #10/#11/#12; merges #32.)* Depends on A3.

### EPIC D — Scripts CRUD (nested + shallow)
- **D1 — ScriptsController + views.** Nested `index/new/create`, shallow `show/edit/update/destroy`; fill `index`/`new`/`show`, add `edit`/`_form`. Show has "Turn into LinkedIn post" CTA. Depends on C1.

### EPIC E — LinkedIn Posts CRUD (singular nested)
- **E1 — LinkedinPostsController + views.** `show/new/create/edit/update/destroy` via `@script.build_linkedin_post`; fill `new`/`show`, add `edit`/`_form`, remove dead `index`. Show CTAs to dashboard / new idea. Depends on D1.

### EPIC F — Polymorphic Chat + Creator-Aware LLM
- **F1 — `chattable` association.** Migration adding `chattable_type`/`chattable_id` to `chats` (+ index); `Chat belongs_to :chattable, polymorphic: true, optional: true`; `has_many :chats, as: :chattable` on User/Idea/Script/LinkedinPost. **Creator owns no chats** (see decision 4 — User is the single top-level owner). *(#34 and #29 already merged — no live coordination needed.)*
- **F2 — Wire chat entry points** into idea/script/post show pages reusing existing chat UI + `ChatResponseJob`. *(Supersedes #33; aligns with #15/#16.)* Depends on F1 + C1/D1/E1. **⚠️ SUPERSEDED** — reframed by the [Chat-driven Generation addendum](#addendum--chat-driven-generation-f2f4-reframe) below.
- **F3 — Cascading context injection.** `app/services/llm_context.rb` walks ancestry (`LinkedinPost → Script → Idea → User → Creator`) building a layered system prompt: Idea→creator profile; Script→+parent idea; Post→+parent idea+parent script (incl. `scripts.system_prompt`). Apply via `chat.with_instructions(LlmContext.for(chattable))` in `ChatsController#create`. Depends on F1. **✅ DONE.**
- **F4 — Structured generation via `RubyLLM::Schema`.** `IdeaSchema{title,description,topic}`, `ScriptSchema{title,description,style,length}`, `LinkedinPostSchema{title,hook,body}` in `app/schemas/`; attach with `with_schema` on the generation path; parse JSON onto records. Free-form refinement stays schema-less. Depends on F2/F3. **⚠️ SUPERSEDED** — schema classes built; `with_schema` wiring is now folded into the [Chat-driven Generation addendum](#addendum--chat-driven-generation-f2f4-reframe) below.

### EPIC G — Dashboard content + onboarding guidance
- **G1 — Dashboard content + onboarding banner.** `DashboardController#show` loads `@creator`, `@ideas = current_user.ideas.includes(scripts: :linkedin_post)`, computes step; `dashboard/show.html.erb` + `_onboarding_banner.html.erb`. Depends on C1/D1/E1; uses A3 helpers.

### EPIC H — Authorization hardening
- **H1 — Cross-user authorization** for scripts/posts (find through `current_user`/`idea.user`); optional shared concern. Alongside D1/E1.

## Existing issues — disposition

- **Keep / design follow-ups:** #4 (fields, mostly done), #5 (welcome design → A2), #6 (LLM chat onboarding, deferred), #7 (profile preview), #10/#11/#12 (AI idea feed — separate track), #13/#14 (content studio), #17 (weekly hub).
- **Merge / supersede:** #8 → B1, #32 → C1, #33 → F2, #15/#16 → F2.
- **Coordinate:** #34, #29 with F1 (schema/seed for `chattable`).

## Team division (4 developers)

**Headline:** the dependency chain — not headcount — sets the pace. The critical path is 7 issues deep and strictly sequential:

```
A2 → A3 → C1 → D1 → E1 → F2 → F4
```

A script needs an idea; a post needs a script; chat wiring needs the show pages. So 4 devs ≈ the speed of this spine, with the side branches (A1, B1, F1, F3, G1, H1) done in parallel "for free" around it. Keep one focused owner driving the spine; absorb everything else alongside.

### Lanes (by ownership)

| Dev | Lane | Issues |
|-----|------|--------|
| **Dev 1** | Foundation & Dashboard | A2 → A3 → G1 |
| **Dev 2** | Content CRUD spine (pace-setter) | C1 → D1 → E1 |
| **Dev 3** | Chat & LLM | F1 → F3 → F2 → F4 |
| **Dev 4** | Shell, Profile & Auth | A1 → B1 → H1 |

### Wave schedule

| Wave | Dev 1 | Dev 2 | Dev 3 | Dev 4 |
|------|-------|-------|-------|-------|
| 1 | **A2** | *prep: shared `_form`/view + Tailwind kit* | **F1** | **A1** |
| 2 | **A3** | **C1** (← A3) | **F3** (← F1) | **B1** (← A3) |
| 3 | *pair on spine* | **D1** | **F2** idea-chat (← C1) | *UI polish / pair* |
| 4 | *pair on spine* | **E1** | **F2** extend to scripts | **H1** (alongside D1/E1) |
| 5 | **G1** (← E1) | review | **F2** finish (posts) → **F4** | review / E2E |

### Make it work
1. **A2 + A3 unblock everyone** — Dev 2 and Dev 4 are idle until A3 lands. Consider Dev 1 + Dev 2 **pairing on A2→A3 in Wave 1** to finish it a day early and shorten the whole project.
2. **Dev 2 is the bottleneck.** When Dev 1 frees up after A3, the highest-leverage move is to **pair on the C1→D1→E1 spine**, not start new side work.

### Coordination hotspots (shared files)
- `app/controllers/application_controller.rb` — A3 (Dev 1) + H1 (Dev 4). Mitigate: H1 lives in a concern (`app/controllers/concerns/`) with a one-line `include`.
- `app/models/user.rb` — A3 only (Dev 1).
- `app/views/layouts/application.html.erb` — A1 only (Dev 4).
- `config/routes.rb` — only A2 adds a route (resource routes already exist).
- `ChatsController#create` — F2 + F3, same owner (Dev 3).

With H1 as a concern, there is effectively no cross-dev file contention.

## Teaching notes (per CLAUDE.md)

Each EPIC's implementation must explain: `resources ... shallow: true` helper split (`idea_scripts_path` vs `script_path`), singular `resource :linkedin_post` (no index, id-less paths), implicit template lookup for each filled-in view, and `form_with model:` create-vs-update inference. All JS as Stimulus controllers.

## End-to-end verification

1. **First-run:** sign up → `new_creator_path` → submit creator → `new_idea_path` → create idea → "Write a script" → create script → "Turn into LinkedIn post" → create post → "Go to dashboard" → dashboard shows the chain + hidden/complete banner.
2. **Returning:** sign out/in → `dashboard_path` → "New idea" → repeat from dashboard, never gated.
3. **Guided-but-skippable:** creator-but-no-ideas user can still visit `/models`, `/chats`; banner shows next step = idea.
4. **Cascading chat:** idea chat → system message has creator topic/goal/audience; script chat → +parent idea; post chat → +idea+script. Generation path → `with_schema` JSON maps onto records.
5. **Authorization:** user B hitting user A's `script_path`/`linkedin_post_path` → blocked.
6. Run `bin/rails test` after each EPIC.

---

## Addendum — Chat-driven Generation (F2/F4 reframe)

> Written 2026-06-04. Reframes the original **F2** (chat links on show pages) and **F4** (schema
> wiring) into a single **generate-via-chat** flow on each `new` action. F1 (`chattable`) and F3
> (`LlmContext`) are done and unchanged; F4's schema classes are built and get wired here.
> **Scope decision (5 days / 4 devs, shared with other features):** ship **generate** for
> idea/script/post now; **refine** (chat-edit an existing record) is a deferred follow-up that
> reuses the same engine.

### The flow

Each `new` action **redirects** to the existing chat composer (`/chats/new`), carrying a
`purpose` + the chattable context. The user converses freely (existing streaming path, with
`LlmContext` instructions applied as today). The chat show page then offers a single
**"save as idea / script / post"** button that runs a **one-shot structured extraction** and
creates the record.

```
ideas#new            → /chats/new?purpose=generate_idea&chattable_type=User&chattable_id=…
scripts#new (@idea)  → /chats/new?purpose=generate_script&chattable_type=Idea&chattable_id=…
posts#new   (@script)→ /chats/new?purpose=generate_linkedin_post&chattable_type=Script&chattable_id=…
```

### `purpose` — the discriminator

A chat carries a `purpose` because chattable type alone is ambiguous (a chat on an `Idea` could
mean "refine this idea" or "generate a child script"). MVP values: `generate_idea`,
`generate_script`, `generate_linkedin_post` (nil = a plain free-form chat, behavior unchanged).
The deferred refine work adds `refine_idea / refine_script / refine_linkedin_post`.

| purpose | schema | chattable (context) | resolve owner via | persist | redirect |
|---|---|---|---|---|---|
| `generate_idea` | `IdeaSchema` | current_user | self | `current_user.ideas.create` | `idea_path` |
| `generate_script` | `ScriptSchema` | Idea | `current_user.ideas.find` | `idea.scripts.create` | `script_path` |
| `generate_linkedin_post` | `LinkedinPostSchema` | Script | `current_user_scripts.find` | post exists? `update` : `build_linkedin_post.save` | `script_linkedin_post_path` |

Permitted keys — Idea `[:title,:description,:topic]`; Script `[:title,:description,:style,:length]`;
LinkedinPost `[:title,:hook,:body]`. Always `symbolize_keys.slice(*permitted)` before writing.

### Generation engine

`chats/show` renders a conditional `button_to` → nested **singular** `resource :generation` →
`GenerationsController#create` (synchronous):

1. Re-resolve & **authorize** the chattable through user-scoped relations (don't trust
   `chat.chattable`); `find` on a scoped relation → 404 for non-owners.
2. Build a transcript from the chat's visible user/assistant messages.
3. Extract on a **transient** chat (keeps the visible transcript clean):
   `RubyLLM.chat(model:).with_instructions(…).with_schema(plan.schema).ask(transcript)`.
   On success `message.content` is a parsed **Hash** (gem `JSON.parse`s it).
4. **Fallback** if the endpoint rejects `response_format: json_schema`: retry without a schema,
   instruct "respond with only a JSON object with keys …", strip ```` ```json ```` fences,
   `JSON.parse` with rescue.
5. Validate keys present → `symbolize_keys.slice(*permitted)` → non-bang `create`/`update` with an
   error branch → redirect to the record (`linkedin_post.present?` guard for the singular post).

`GenerationPlan` (a PORO in `app/services/`) holds the table above as the single source of truth;
`current_user_linkedin_posts` is added to `UserScopedResource`.

> **Endpoint risk (gated):** structured output via `with_schema` is **not guaranteed** on the
> GitHub-Models/Azure `gpt-4o-mini` endpoint. A **day-1 spike (F-3)** verifies it; if it fails the
> prompt-JSON fallback becomes the default path. Verified in `ruby_llm-1.15.0`:
> `chat.with_schema` delegates to the in-memory chat (`chat_methods.rb:154`) and the gem silently
> falls back to the raw String on a parse failure (`chat.rb:172`).

### Fold-in cleanup

Remove `readonly: true` from `ideas/_form.html.erb` (broke editing); delete
`IdeasController#generate_idea`, the `post :generate_idea` route, and `_generate_idea_form.html.erb`
(+ its render in `ideas/new`). `resources :generated_ideas` is left alone (separate AI-feed track).

### Teaching notes (per CLAUDE.md)

`enum purpose` (string column → predicate/bang methods + inclusion validation); singular
`resource :generation` (no `:id` segment → `POST /chats/:chat_id/generation`, like
`resource :creator`); the conventional `new` action repurposed as a `redirect_to`;
`button_to` / `form_with url:` route inference; implicit template lookup (none — the action
redirects). All client JS as Stimulus controllers.

### Issue set (project #5 "Content Flow KanBan", label *Chat Refinement*)

**EPIC — Chat-driven Generation (RubyLLM).** Supersedes #48 (F2), #71 (F4), #33, #15, #16.

| Issue | Depends | Lane | Summary |
|---|---|---|---|
| **F-1** Chat `purpose` foundation | — | Dev 3 | migration + `enum purpose` + carry/persist through `chats#new/#create` + hidden field |
| **F-2** Generation engine | F-1, F-3 | Dev 3 | `resource :generation` + `GenerationPlan` + `GenerationsController#create` + `current_user_linkedin_posts` |
| **F-3** `with_schema` spike + JSON fallback (day-1 hard gate) | — | Dev 1 | verify schema vs endpoint; build the reusable fallback |
| **F-4** Generate entry points + dead-code cleanup | F-1 | Dev 2 | redirect the three `new` actions; remove `generate_idea` stub + readonly |
| **F-5** Chat-show "save as …" action + styling | F-2 | Dev 4 | conditional `button_to`; restyle chat show/composer to DESIGN.md |
| **F-6** Tests + E2E | F-2,F-4,F-5 | pairing | request specs per purpose + first-run journey; `bin/rails test` green |
| *Deferred* Refine via chat | EPIC | — | add `refine_*` purposes + show-page links + update rows in `GenerationPlan` (folds in #15/#16) |

### 5-day sequencing (4 devs)

Critical path: **F-3 gate (day 1) → F-1 → F-2 → F-5 → F-6**, mostly owned by Dev 3.

| Day | Dev 3 (Chat&LLM) | Dev 1 (de-risk) | Dev 2 (Content CRUD) | Dev 4 (Shell/UI) |
|---|---|---|---|---|
| 1 | **F-1** | **F-3** spike — gate by EOD | other feature | chat UI restyle groundwork |
| 2 | **F-2** start | support F-2 | **F-4** (after F-1) | other feature |
| 3 | **F-2** finish | start **F-5** controller side | **F-4** done → other | **F-5** styling (after F-2) |
| 4 | pair **F-6** specs | **F-6** specs (pair) | other feature | **F-5** + polish |
| 5 | review/buffer | **F-6** + E2E | other feature | E2E + polish |

Merge **F-1 fast** (unblocks F-4); **F-2 is the bottleneck** — once it lands (~day 3) Devs 2/4 roll
onto other features. Coordination is low: F-1/F-2 touch chat files (Dev 3 only); F-4 touches content
`new` actions + `ideas/_form` (Dev 2); F-5 touches `chats/show` (Dev 4); the one shared file is
`config/routes.rb` (F-2 adds the generation route, F-4 removes `generate_idea`).
