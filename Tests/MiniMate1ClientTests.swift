// Manual Test Plan for MiniMate1Client
//
// Note: Swift executable targets cannot have unit tests in the same package.
// To add proper unit tests, the code needs to be refactored into a library target.
//
// For now, perform these manual tests:
//
// 1. Model Tests:
//    - Test Hint model can decode JSON from API
//    - Test PendingHintsResponse decodes correctly
//    - Test ActivityReportItem encodes with correct snake_case keys
//    - Test all enum raw values match API contract
//
// 2. APIClient Tests:
//    - Test device ID generation is consistent
//    - Test health check endpoint
//    - Test getPendingHints() with mock server
//    - Test updateHintStatus() sends correct PATCH request
//    - Test reportActivity() sends correct POST request
//
// 3. HintService Tests:
//    - Test polling starts and stops correctly
//    - Test fetchHints() updates pendingHints array
//    - Test showHint() marks hint as shown
//    - Test dismissCurrentHint() marks as dismissed and shows next
//
// 4. UI Tests:
//    - Test companion window appears on launch
//    - Test window can be dragged and stays on screen
//    - Test speech bubble appears when hint is available
//    - Test dismiss button removes hint and shows next
//    - Test hover animation on character
//    - Test menu bar toggle works
//
// To run the app manually:
//   cd /Users/mohamedayman/hackathon-ws/apps/macos-client
//   swift run MiniMate1Client
