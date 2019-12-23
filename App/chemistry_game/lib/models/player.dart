import 'package:chemistry_game/models/element_card.dart';
import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';

class Player{

  final String name;
  final String id;
  final points = 0;
  Multimap<String, ElementCard> elementCards = Multimap<String, ElementCard>();
  /*{
    "H2" : ElementCard(name: "H2", group: "2A", period: 2),
    "02" : ElementCard(name: "02", group: "2A", period: 1),
    "A" : ElementCard(name: "A", group: "1A", period: 3),
    "B" : ElementCard(name: "B", group: "3A", period: 1),
    "C" : ElementCard(name: "C", group: "3A", period: 2),
    "D" : ElementCard(name: "D", group: "2A", period: 3),
    "F" : ElementCard(name: "F", group: "1A", period: 1),
    "E" : ElementCard(name: "E", group: "3A", period: 2)
  }*/

  void setElementCards() {
    elementCards.add("H2", ElementCard(name: "H2", group: "2A", period: 2));
    elementCards.add("H2", ElementCard(name: "H2", group: "2A", period: 2));
    elementCards.add("02", ElementCard(name: "02", group: "2A", period: 1));
    elementCards.add("A", ElementCard(name: "A", group: "1A", period: 3));
    elementCards.add("B", ElementCard(name: "B", group: "3A", period: 1));
    elementCards.add("C", ElementCard(name: "C", group: "3A", period: 2));
    elementCards.add("D", ElementCard(name: "D", group: "2A", period: 3));
    elementCards.add("F", ElementCard(name: "F", group: "1A", period: 1));
    elementCards.add("E", ElementCard(name: "E", group: "3A", period: 2));
  }

  //TODO: add combinationCards and acceletorCard

  Player({this.name, this.id});

  List<ElementCard> getElementCards() {
    return elementCards.values.toList();
  }

  void removeElementCard(ElementCard elementCard) {
    elementCards.remove(elementCard.name, elementCard);
    //TODO : also remove in the database
  }

  void addElementCard(ElementCard elementCard) {
    elementCards.add(elementCard.name, elementCard);
  }
}