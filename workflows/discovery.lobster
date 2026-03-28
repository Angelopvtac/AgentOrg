# Discovery Pipeline (L1)
#
# Trigger: Phase transition to L1, or orchestrator dispatch on founder research request
# Owner: orchestrator (dispatches), research agent (executes)
# Phase: L1 (Discovery) — this pipeline drives all three L1 gate criteria
#
# Gate criteria this pipeline satisfies:
#   1. direction-selected — vault/business/direction.json has non-null fields
#   2. brand-brief-complete — vault/business/brand-brief.json has required fields
#   3. market-research-done — vault/research/ contains at least one report

---
pipeline: discovery
version: 1.0.0
trigger:
  type: event
  events:
    - phase_transition_to_L1
    - founder_research_request
  guard: vault/phase-state.json → currentPhase == "L1"

---

## Step 1: Founder Profile Ingestion

agent: research
tier: 2
input:
  - vault/founder-profile.json
output:
  - founder_context

actions:
  - Read vault/founder-profile.json thoroughly
  - Extract research-relevant dimensions:
    - skills[] — what the founder can do (name, level, relevance)
    - goals.primary — what they want to achieve
    - goals.interests[] — industries or areas they're drawn to
    - goals.timeline — urgency constraint
    - financial.investmentCapacity — capital available
    - financial.riskTolerance — conservative / moderate / aggressive
    - availability.weeklyHours — time constraint
    - vision.statement — stated vision and direction

validation:
  - Fail if founder-profile.json is empty or has null personalInfo.name (onboarding not complete)
  - Log warning if skills array has fewer than 3 entries

---

## Step 2: Market Scan

agent: research
tier: 2
input:
  - founder_context (from Step 1)
output:
  - vault/research/market-scan-{date}-{slug}.json

actions:
  - For each intersection of skill x interest x market opportunity:
    - Use web_search to research market size, competition, trends
    - Evaluate founder-market fit based on skills, capital, time constraints
  - For each viable direction found, create structured analysis:
    - Direction name
    - Target audience
    - Revenue model (how it makes money)
    - Competitive landscape (key players, saturation level)
    - Founder Fit Score (1-10) based on skill match, time requirement, capital requirement
    - Time to First Revenue estimate
    - Required Capital estimate
    - Risk Level (Low / Medium / High)
    - Key Risks (top 3)
    - Key Advantages (top 3, especially founder-specific advantages)
    - Confidence (High / Medium / Low)
    - Sources (URLs, dates)
  - Score and rank all viable directions
  - Select top 3-5 directions for presentation
  - Write full report to vault/research/ following the research report schema:
    ```json
    {
      "id": "market-scan-{date}-{slug}",
      "type": "market-scan",
      "title": "Market Scan: {founder_name} — Skill-Market Fit Analysis",
      "createdAt": "{ISO 8601}",
      "updatedAt": "{ISO 8601}",
      "phase": "L1",
      "summary": "{2-3 sentence executive summary}",
      "findings": [ { "finding": "...", "confidence": "...", "source": "...", "sourceDate": "..." } ],
      "directions": [ { structured analysis per direction } ],
      "recommendations": [ { "action": "...", "rationale": "...", "priority": "..." } ],
      "metadata": { "searchQueries": [...], "sourcesConsulted": N, "modelTier": "Tier 2" }
    }
    ```

gate_progress: market-research-done → SATISFIED (report exists in vault/research/)

notification:
  - Send to orchestrator: "Market scan complete. {N} viable directions identified. Top direction: {name} (Fit Score: {score}/10). Report: vault/research/{filename}"
  - Orchestrator relays summary + top directions to core-assistant for founder review

---

## Step 3: Founder Direction Selection

agent: core-assistant
tier: 2
input:
  - Market scan summary (relayed from orchestrator)
  - vault/research/market-scan-*.json (for detail queries)
output:
  - selected_direction

actions:
  - Present top 3-5 directions to founder in a readable format:
    - For each direction: name, target audience, revenue model, fit score, time-to-revenue, risk level
    - Highlight founder-specific advantages
  - Answer founder questions about specific directions (pull from research report)
  - When founder selects a direction, confirm the choice
  - Notify orchestrator of selection: "Founder selected direction: {name}"
  - Orchestrator dispatches deep-dive request to research agent

founder_interaction:
  - Allow comparison: "Tell me more about direction 2 vs 3"
  - Allow rejection: "None of these feel right — can we look at {different angle}?"
    → If rejected, return to Step 2 with adjusted parameters
  - Allow partial selection: "I like aspects of 1 and 3"
    → Research agent can create a hybrid direction analysis

---

## Step 4: Competitive Deep-Dive

agent: research
tier: 3
input:
  - selected_direction (from Step 3)
  - vault/founder-profile.json (for positioning angles)
output:
  - vault/research/competitive-analysis-{date}-{slug}.json
  - vault/business/direction.json (updated)

actions:
  - Perform detailed competitive analysis at Tier 3:
    - Direct competitors (same market, same approach)
    - Indirect competitors (same market, different approach)
    - Adjacent players (different market, could pivot in)
    - Market size estimates (TAM, SAM, SOM where data exists)
  - Identify positioning opportunities:
    - Gaps in competitor offerings
    - Underserved audience segments
    - Founder's unique advantages vs each competitor
  - Write competitive analysis report to vault/research/
  - Update vault/business/direction.json with selected direction data:
    ```json
    {
      "direction": "{selected direction name}",
      "description": "{2-3 sentence description}",
      "targetMarket": "{who this serves}",
      "revenueModel": "{how it makes money}",
      "selectedAt": "{ISO 8601}",
      "founderFitScore": N,
      "competitivePosition": "{differentiation summary}",
      "keyCompetitors": ["{name1}", "{name2}", "{name3}"],
      "timeToRevenue": "{estimate}",
      "riskLevel": "{Low|Medium|High}"
    }
    ```

gate_progress: direction-selected → SATISFIED (direction.json has non-null fields)

notification:
  - Send to orchestrator: "Competitive analysis complete for {direction}. {N} direct competitors, {N} indirect. Positioning opportunity: {key gap}. Direction data written to vault."

---

## Step 5: Brand Brief Research

agent: research
tier: 2
input:
  - vault/business/direction.json (confirmed direction)
  - vault/founder-profile.json (preferences, communication style)
output:
  - vault/research/brand-research-{date}-{slug}.json

actions:
  - Research naming conventions in the target market:
    - Analyze competitor brand names (style, length, feeling)
    - Propose 5-7 name candidates with rationale
  - Research brand positioning in the space:
    - Map competitor positioning on axes (premium vs affordable, specialist vs generalist)
    - Identify open positioning territory
  - Research available domains and social handles:
    - Check domain availability patterns via web search
    - Check key social platform handle availability
  - Analyze competitor tone and voice:
    - Formal vs casual spectrum
    - Technical vs accessible spectrum
    - Recommend tone based on positioning gap + founder style
  - Write brand research report to vault/research/

notification:
  - Send to orchestrator: "Brand research complete. {N} name candidates proposed. Positioning recommendation: {summary}. Report: vault/research/{filename}"
  - Orchestrator relays to core-assistant for founder review

---

## Step 6: Brand Brief Completion

agent: core-assistant
tier: 2
input:
  - Brand research summary (relayed from orchestrator)
  - vault/research/brand-research-*.json (for details)
  - vault/founder-profile.json (preferences)
output:
  - vault/business/brand-brief.json (updated)

actions:
  - Present brand research findings to founder:
    - Name candidates with rationale
    - Positioning recommendation with market map
    - Tone and voice recommendation
    - Available domains/handles
  - Collaborate with founder on decisions:
    - Brand name selection (or founder provides their own)
    - Positioning statement refinement
    - Tone of voice agreement
    - Tagline co-creation
  - Update vault/business/brand-brief.json:
    ```json
    {
      "brandName": "{chosen name}",
      "tagline": "{tagline}",
      "positioning": "{positioning statement}",
      "tone": "{tone description — e.g., 'Professional but approachable, technically credible without jargon'}",
      "targetAudience": "{audience description}",
      "voiceAttributes": ["{attribute1}", "{attribute2}", "{attribute3}"],
      "colorDirection": "{optional — mood/feeling, not specific hex values}",
      "completedAt": "{ISO 8601}",
      "completedBy": "core-assistant + founder collaboration"
    }
    ```

gate_progress: brand-brief-complete → SATISFIED (brand-brief.json has required fields)

founder_interaction:
  - Allow iterating on name: "I don't love any of these — what about something with 'craft' in it?"
  - Allow founder to bring their own name: "I already have a name — it's Meridian"
  - Allow partial decisions: "Let's lock in the name and positioning but revisit tone later"
    → Mark incomplete fields, pipeline can re-enter at Step 6

---

## Step 7: L1 Gate Verification

agent: orchestrator
tier: 3
input:
  - vault/business/direction.json
  - vault/business/brand-brief.json
  - vault/research/ (report count)
output:
  - vault/phase-state.json (updated gateResults)

actions:
  - Evaluate all three L1 gate criteria at Tier 3:
    1. direction-selected: vault/business/direction.json has non-null direction, targetMarket, description
    2. brand-brief-complete: vault/business/brand-brief.json has non-null brandName, positioning, tone
    3. market-research-done: vault/research/ contains at least one .json report
  - Update vault/phase-state.json gateResults with evaluation
  - If all 3 pass:
    - Trigger phase transition L1 → L2
    - Update vault/phase-state.json (currentPhase, phaseName, phaseStartDate)
    - Log transition in history
    - Notify founder via core-assistant: "Discovery phase complete! Moving to L2 (Presence). Content and social agents are now available."
  - If not all pass:
    - Report which criteria remain unmet
    - The pipeline continues — founder can return to incomplete steps

---

## Error Handling

- If founder-profile.json is empty/incomplete: Abort pipeline, notify orchestrator that onboarding must be complete before discovery
- If web_search fails: Log error, attempt alternate search queries, report partial results with lower confidence
- If founder rejects all directions: Return to Step 2 with refined parameters based on founder feedback
- If vault write fails: Retry once, then notify orchestrator of write failure
- If research agent is unreachable: Orchestrator queues request and retries on next heartbeat cycle

## Pipeline State

The discovery pipeline is NOT a single continuous execution. It progresses through founder interactions
that may span hours or days. State is tracked implicitly through vault files:

- Step 1-2 complete when: vault/research/ has a market-scan report
- Step 3 complete when: vault/business/direction.json has non-null direction field
- Step 4 complete when: vault/research/ has a competitive-analysis report AND direction.json is fully populated
- Step 5 complete when: vault/research/ has a brand-research report
- Step 6 complete when: vault/business/brand-brief.json has required fields
- Step 7 complete when: vault/phase-state.json shows L1 gate all-pass

To resume the pipeline after interruption, check which vault files exist and
re-enter at the appropriate step.

## Success Criteria

The pipeline succeeds when all three L1 gate criteria pass:
1. direction-selected — founder has a documented business direction with target market
2. brand-brief-complete — brand brief has name, positioning, and tone defined
3. market-research-done — at least one structured research report exists in vault
