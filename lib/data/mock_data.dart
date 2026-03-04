import 'package:projet_sejour/models/announcement.dart';
import 'package:projet_sejour/models/itinerary_item.dart';

final List<Announcement> mockAnnouncements = [
  Announcement(
    title: 'Schedule Update',
    time: '10 mins ago',
    description:
        'The visit to the ancient monastery has been moved to 14:00 due to weather conditions. Please gather at the main square.',
    type: AnnouncementType.important,
    isPinned: true,
  ),
  Announcement(
    title: 'Lunch Menu Change',
    time: '1 hour ago',
    description:
        'Today\'s lunch at Café des Pèlerins will feature a special regional stew. Vegetarian options are still available upon request to your group leader.',
    type: AnnouncementType.info,
  ),
  Announcement(
    title: 'Weather Alert',
    time: '2 hours ago',
    description:
        'Light rain is expected this afternoon. Please ensure you bring your umbrellas and waterproof jackets for the monastery visit.',
    type: AnnouncementType.alert,
  ),
  Announcement(
    title: 'Evening Mass',
    time: '3 hours ago',
    description:
        'Evening mass will be held at 18:00 instead of 18:30 today in the main chapel.',
    type: AnnouncementType.info,
  ),
  Announcement(
    title: 'Lost and Found',
    time: '5 hours ago',
    description:
        'A blue water bottle was found near the dining area. Please contact the front desk if it belongs to you.',
    type: AnnouncementType.info,
  ),
  Announcement(
    title: 'Bus Departure Delay',
    time: '1 day ago',
    description:
        'Tomorrow morning\'s bus to the remote shrine will depart at 09:15 due to scheduled road maintenance.',
    type: AnnouncementType.important,
  ),
];

final List<ItineraryItem> mockItinerary = [
  ItineraryItem(
    time: '08:00',
    title: 'Morning Prayer & Assembly',
    location: 'Hotel Lobby',
    isPast: true,
  ),
  ItineraryItem(
    time: '09:30',
    title: 'Departure to Reims Cathedral',
    location: 'Bus 2',
    isPast: true,
  ),
  ItineraryItem(
    time: '10:15',
    title: 'Guided Tour: Footsteps of the Founder',
    location: 'Reims Cathedral',
    isCurrent: true,
  ),
  ItineraryItem(
    time: '12:30',
    title: 'Group Lunch & Reflection',
    location: 'Café des Pèlerins',
  ),
  ItineraryItem(
    time: '14:00',
    title: 'Visit to the Ancient Monastery',
    location: 'North Wing',
  ),
  ItineraryItem(
    time: '17:00',
    title: 'Return & Evening Free Time',
    location: 'City Center',
  ),
];
