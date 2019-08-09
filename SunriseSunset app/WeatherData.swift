//
//  File.swift
//  WeatherApp
//
//  Created by Володимир Смульський on 20/07/19.
//  Copyright © 2018 Володимир Смульський. All rights reserved.
//

import Foundation

class Weather: NSObject {
    var sunrise: String
    var sunset : String
    
    init(sunrise: String, sunset: String) {
        self.sunset  = sunset
        self.sunrise = sunrise
    }
}

class DataForTimezoneRequest: NSObject {
    var summerTimedstOffset : Int
    var numberOfTimeZonerawOffset : Int
    
    init(summerTime: Int, numberOfTimeZone: Int ) {
        self.summerTimedstOffset = summerTime
        self.numberOfTimeZonerawOffset = numberOfTimeZone
    }
}

