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
- **F2 — Wire chat entry points** into idea/script/post show pages reusing existing chat UI + `ChatResponseJob`. *(Supersedes #33; aligns with #15/#16.)* Depends on F1 + C1/D1/E1.
- **F3 — Cascading context injection.** `app/services/llm_context.rb` walks ancestry (`LinkedinPost → Script → Idea → User → Creator`) building a layered system prompt: Idea→creator profile; Script→+parent idea; Post→+parent idea+parent script (incl. `scripts.system_prompt`). Apply via `chat.with_instructions(LlmContext.for(chattable))` in `ChatsController#create`. Depends on F1.
- **F4 — Structured generation via `RubyLLM::Schema`.** `IdeaSchema{title,description,topic}`, `ScriptSchema{title,description,style,length}`, `LinkedinPostSchema{title,hook,body}` in `app/schemas/`; attach with `with_schema` on the generation path; parse JSON onto records. Free-form refinement stays schema-less. Depends on F2/F3.

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
