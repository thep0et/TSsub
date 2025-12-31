# TSsub
Transport Stream subscriber For data gathering and analytics

Academically published project.  Details found here:
https://docs.google.com/document/d/1NeTRCbejRKHQ-cgCYmIUu4uKUYGlUGYTlPPitHS9tYY/edit?usp=sharing

Script uses TSDUCK filters to capture and filter out cue tones, then forwards them to logstash via the crontab by directing output to /dev/udp with no need to store logs locally.
Each service subscription pulls from a list of services which are dynamically updated from ES data.  
Each “listener” operates as individual “microservices”.  With no data stored locally, just passed through, the script is lightweight and easily scalable.  
Any updates to RHEL OS that include changes to the ways ports are bound could be potentially breaking changes.  Please keep this in mind.
