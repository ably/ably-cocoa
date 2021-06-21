//
//  Stringifiable.swift
//  Ably
//
//  Created by Łukasz Szyszkowski on 21/06/2021.
//  Copyright © 2021 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble

class Stringifiable: QuickSpec {
    override func spec() {
        describe("Stringifiable") {
            context("type conversion") {
                it("as string") {
                    expect(
                        ARTStringifiable(string: "Lorem Ipsum").convert()
                    )
                    .to(
                        equal("Lorem%20Ipsum")
                    )
                }
                
                it("as bool [true]") {
                    expect {
                        ARTStringifiable(bool: true).convert()
                    }
                    .to(
                        equal("true")
                    )
                }
                
                it("as bool [false]") {
                    expect {
                        ARTStringifiable(bool: false).convert()
                    }
                    .to(
                        equal("false")
                    )
                }
                
                it("as number [Int]") {
                    expect {
                        ARTStringifiable(number: NSNumber(value: 12)).convert()
                    }
                    .to(
                        equal("12")
                    )
                }
                
                it("as number [Float]") {
                    expect {
                        ARTStringifiable(number: NSNumber(value: 0.12)).convert()
                    }
                    .to(
                        equal("0.12")
                    )
                }
            }
        }
    }
}
