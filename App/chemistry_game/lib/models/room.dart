import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/fieldPlayer.dart';
import 'package:chemistry_game/models/player.dart';

class Room
{
  Player player;
  List<FieldPlayer> otherPlayers;
  String roomId;
  ElementCard lastCard;
}