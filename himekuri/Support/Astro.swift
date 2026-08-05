//
//  Astro.swift
//  himekuri
//
//  The small amount of astronomy a lunisolar calendar needs: where the sun
//  sits on the ecliptic (which fixes the 24 solar terms) and how much of the
//  moon is lit (which is what the calendar's months are counting).
//
//  Low-precision Meeus, chapters 25 and 48. Good to well under a minute for
//  the solar terms, which is far more than a paper calendar ever claimed.
//

import Foundation

nonisolated enum Astro {
    /// Chinese calendrical dates are reckoned at UTC+8 regardless of where the
    /// reader is standing — the same convention ICU's chinese calendar uses,
    /// so the terms computed here line up with the lunar dates elsewhere.
    /// A fixed offset inside ±18h always yields a zone, hence the unwrap.
    static let chinaTimeZone = TimeZone(secondsFromGMT: 8 * 3600)!

    static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400 + 2440587.5
    }

    /// Julian centuries from J2000.0.
    private static func centuries(_ jd: Double) -> Double {
        (jd - 2451545.0) / 36525
    }

    private static func radians(_ deg: Double) -> Double { deg * .pi / 180 }

    /// Normalise to [0, 360).
    static func normalize(_ deg: Double) -> Double {
        let d = deg.truncatingRemainder(dividingBy: 360)
        return d < 0 ? d + 360 : d
    }

    /// The sun's apparent ecliptic longitude, in degrees.
    static func sunLongitude(_ date: Date) -> Double {
        let t = centuries(julianDay(date))

        // Geometric mean longitude and mean anomaly.
        let l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        let m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t
        let mr = radians(m)

        // Equation of the centre.
        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mr)
            + (0.019993 - 0.000101 * t) * sin(2 * mr)
            + 0.000289 * sin(3 * mr)

        // Aberration and the dominant nutation term.
        let omega = radians(125.04 - 1934.136 * t)
        return normalize(l0 + c - 0.00569 - 0.00478 * sin(omega))
    }

    /// The moon's apparent ecliptic longitude, in degrees. Only the largest
    /// periodic terms — enough to place the phase, not to predict an eclipse.
    static func moonLongitude(_ date: Date) -> Double {
        let t = centuries(julianDay(date))

        let lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t   // mean longitude
        let d = radians(297.8501921 + 445267.1114034 * t)                // mean elongation
        let m = radians(357.5291092 + 35999.0502909 * t)                 // sun's mean anomaly
        let mp = radians(134.9633964 + 477198.8675055 * t)               // moon's mean anomaly
        let f = radians(93.2720950 + 483202.0175233 * t)                 // argument of latitude

        var lon = lp
        lon += 6.288774 * sin(mp)
        lon += 1.274027 * sin(2 * d - mp)
        lon += 0.658314 * sin(2 * d)
        lon += 0.213618 * sin(2 * mp)
        lon -= 0.185116 * sin(m)
        lon -= 0.114332 * sin(2 * f)
        lon += 0.058793 * sin(2 * d - 2 * mp)
        lon += 0.057066 * sin(2 * d - m - mp)
        lon += 0.053322 * sin(2 * d + mp)
        lon += 0.045758 * sin(2 * d - m)
        lon -= 0.040923 * sin(m - mp)
        lon -= 0.034720 * sin(d)
        lon -= 0.030383 * sin(m + mp)
        return normalize(lon)
    }

    /// Fraction of the moon's disc that is lit, 0 (new) … 1 (full).
    static func moonIllumination(_ date: Date) -> Double {
        let elongation = radians(normalize(moonLongitude(date) - sunLongitude(date)))
        return (1 - cos(elongation)) / 2
    }

    /// True when the moon is waxing — lit edge on the right, in the north.
    static func moonIsWaxing(_ date: Date) -> Bool {
        normalize(moonLongitude(date) - sunLongitude(date)) < 180
    }
}
