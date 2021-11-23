import Ably
import Nimble
import Quick
import SwiftyJSON

            private let links = "<./messages?start=0&end=1535035746063&limit=100&direction=backwards&format=msgpack&firstEnd=1535035746063&fromDate=1535035746063&mode=all>; rel=\"first\", <./messages?start=0&end=1535035746063&limit=100&direction=backwards&format=msgpack&firstEnd=1535035746063&fromDate=1535035746063&mode=all>; rel=\"current\""

            private let url = URL(string: "https://sandbox-rest.ably.io:443/channels/foo/messages?limit=100&direction=backwards")!

class RestPaginated : XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = links
    let _ = url

    return super.defaultTestSuite
}

        

            func test__001__RestPaginated__should_extract_links_from_the_response() {
                guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Link": links]) else {
                    fail("Invalid HTTPURLResponse"); return
                }
                guard let extractedLinks = response.extractLinks() else {
                    fail("Couldn't extract links from response"); return
                }
                expect(extractedLinks.keys).to(contain("first" ,"current"))
            }

            func test__002__RestPaginated__should_create_next_first_last_request_from_extracted_link_path() {
                let request = URLRequest(url: url)

                guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Link": links]) else {
                    fail("Invalid HTTPURLResponse"); return
                }
                guard let extractedLinks = response.extractLinks() else {
                    fail("Couldn't extract links from response"); return
                }
                expect(extractedLinks.keys).to(contain("first" ,"current"))

                guard let firstLink = extractedLinks["first"] as? String else {
                    fail("First link is missing from extracted links"); return
                }

                guard let firstRequest = NSMutableURLRequest(path: firstLink, relativeTo: request) else {
                    fail("First link isn't a valid URL"); return
                }

                expect(firstRequest.url?.absoluteString).to(equal("https://sandbox-rest.ably.io:443/channels/foo/messages?start=0&end=1535035746063&limit=100&direction=backwards&format=msgpack&firstEnd=1535035746063&fromDate=1535035746063&mode=all"))
            }
}
