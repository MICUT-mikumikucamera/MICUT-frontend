# Product
<!-- impeccable:product-schema 1 -->
## Platform
adaptive
## Stack
Flutter. Backend brief explicitly identifies Flutter + HTTP/JSON, with FastAPI on the server. Android/iOS target; web is a verification surface.
## Product Purpose
MiCut captures a scene and lets the server automatically place Miku into the resulting photograph.
## Evidence on Hand
- User-approved visual reference: https://www.figma.com/design/gaEquzyI3Y2S9lGKfjgaRR/미컷?node-id=33-2
- API brief: docs/api-v0.md
- Backend fixtures: assets/contracts (contracts/v0 branch).
## Capabilities and Constraints
No login. Asynchronous job lifecycle, retry/discard, result image retrieval. Server URL/allowed upload sizes/formats remain unconfirmed. No card acquisition in v0. No server cancellation or gallery API.
## Users
People taking a photo with Miku. Further audience segmentation is undecided.
## Brand Commitments
Use the downloaded Figma source assets and tokens with Korean labels. User-requested departures are documented in README.md; no invented pose art.
