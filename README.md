Screens - information radiators on AirPlay devices
==================================================

Have you ever watched a movie about space missions, with the giant screens on
the wall displaying astronaut and ship status? Have you ever walked into a tech
company and see a TV on the wall showing nothing but colorful charts and
numbers that surely someone thinks are useful? These are called Information
Radiators! They passively present information into the workspace allowing
people to share some context about the work product and the office.

Serious information radiators might say if the system is up or down, or commute
status of nearby public transit and roadways. Fun information radiators might
report on the lunch menu. Ok, lunch can be serious, too.

My big screen pet peeve
-----------------------

I used to work next to a big screen that was always prompting to update the OS,
update the browser, 404 Not Found, Press Any Key... There was a full PC sitting
behind each screen in that office, and they constantly needed manual attention.

When I started work on this project, I gave myself two overarching goals:

1. The cost for each additional screen would be a TV + $200, or less.
2. No significant intervention should be required on a per-screen basis after
   installation day.

Then I realized that these systems exist, and they are called Digital Signage.
Take any normal cost hardware, call it Digial Signage, and you get to
quadruple the price. Next.


Screens - a Rails app that displays to AirPlay devices
------------------------------------------------------

My big epiphany came when I saw the [airplay rubygem](https://github.com/elcuervo/airplay) by @elcuervo.
I could programmatically control and display to an Apple TV! They cost $99,
don't require much maintenance, and setup is a breeze! Here goes!

Screens also works well with XBMC when configured with AirPlay support enabled.
An alternative target device is the Raspberry Pi running OpenELEC.tv. At some
point I'd like to use the RPi's HDMI CEC support for screen power control.


Quick Start
-----------

Requirements:
* A bunch of Apple TV or Raspberry Pi devices!
* Recent Mac OS X or Linux with Avahi/Zeroconf
* MySQL or SQLite
* Ruby 1.9.3 or higher

Setup:

    bundle install
    bundle exec imgkit --install-wkhtmltoimage
    bundle exec rake db:setup
    bundle exec thin start
    bundle exec bin/airserver.rb &

An OpenID authentication method is included in the box, but is optional to use.

By default, thin runs on port 3000. You may want to run nginx as a reverse proxy
on standard HTTP or HTTPS ports.


Power control for Sharp Aquos displays
--------------------------------------

Screens comes with a power on/off script for the IP Control port on many Sharp
Aquos displays. In this example, the script will discover all devices on
interface en3 from the arp table and attempt to telnet to port 10002. This
works well if you put the screens themselves on a separate network.

    # Turn screens on at 9:30am local time Monday - Friday
    30 9 * * 1-5   bin/aquos.rb --quiet --arp en3 --on
    # Turn screens off at 6:30pm local time every day
    30 18 * * *    bin/aquos.rb --quiet --arp en3 --off
