import Ably
import Nimble
import Quick
import SwiftyJSON

class RestPaginated : QuickSpec {
    override func spec() {
        describe("RestPaginated") {

            let links = "<./messages?start=0&end=1535035746063&limit=100&direction=backwards&format=msgpack&firstEnd=1535035746063&fromDate=1535035746063&mode=all>; rel=\"first\", <./messages?start=0&end=1535035746063&limit=100&direction=backwards&format=msgpack&firstEnd=1535035746063&fromDate=1535035746063&mode=all>; rel=\"current\""

            let url = URL(string: "https://sandbox-rest.ably.io:443/channels/foo/messages?limit=100&direction=backwards")!

            it("should extract links from the response") {
                guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Link": links]) else {
                    fail("Invalid HTTPURLResponse"); return
                }
                guard let extractedLinks = response.extractLinks() else {
                    fail("Couldn't extract links from response"); return
                }
                expect(extractedLinks.keys).to(contain("first" ,"current"))
            }

            it("should create next/first/last request from extracted link path") {
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
    }
}
