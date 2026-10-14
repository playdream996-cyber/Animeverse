import 'adventure_rules.dart';
import 'story_catalog.dart';

StoryDefinition lighthouseStory() => StoryDefinition(
  id:'original-lighthouse-v1', title:'The Lighthouse Promise', genre:'Adventure',
  description:'A fading beacon, a missing keeper, and a choice about what it means to bring someone home.',
  art:'assets/art/lantern.png', character:'Mika', tag:'COMPLETE ADVENTURE · 2 ENDINGS',
  opening:'The last lantern is fading.', choices:const [], responses:const [],
  foundation:'Original authored adventure', sourceUrl:'', creator:'Animeverse',
  world:'A coast where lighthouses preserve the memories of safe journeys.', playerRole:'A traveler carrying an unfinished promise',
  goal:'Bring the waiting boats safely home', mode:'Complete adventure', rules:lighthouseRules(),
  tags:const ['Coastal mystery','Choices matter'], ageRating:'Everyone');
