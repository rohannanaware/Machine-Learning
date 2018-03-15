import hlt
import logging
from collections import OrderedDict

# GAME START
# Here we define the bot's name as Settler and initialize the game, including communication with the Halite engine.
game = hlt.Game("Settler")
logging.info("Starting my Settler bot!")

while True:
    # TURN START
    # Update the map for the new turn and get the latest version    
    game_map = game.update_map()
    command_queue = []
    team_ships = game_map.get_me().all_ships()
    # For every ship that I control
    for ship in game_map.get_me().all_ships():
        shipid = ship.id
        if ship.docking_status != ship.DockingStatus.UNDOCKED:
            continue

        entities_by_distance = game_map.nearby_entities_by_distance(ship)
        entities_by_distance = OrderedDict(sorted(entities_by_distance.items(), key = lambda t: t[0]))
        #Contains details on our/enemy ships, planets - docked/undocked, owners of planets

        closest_empty_planets = [entities_by_distance[distance][0] for distance in entities_by_distance if isinstance(entities_by_distance[distance][0], hlt.entity.Planet) and not entities_by_distance[distance][0].is_owned()]
        """Next, we could do some navigating, but, while we're building lists,
           let's build the lists for finding enemy ships too.
           In theory, if there's an empty planet, we really do not care at all about enemy ships,
           at least with this version, since we want to head to the empty planet.
           If we wanted our script to run as quickly as possible, we might hold off on building this list,
           but, there wont be empty planets for long, and you'll be running these lists every time anyway.
           In the name of keeping things all together, let's keep these lists together for now:"""
        closest_enemy_ships = [entities_by_distance[distance][0] for distance in entities_by_distance if isinstance(entities_by_distance[distance][0], hlt.entity.Ship) and entities_by_distance[distance][0] not in team_ships]

        if len(closest_empty_planets) > 0:
            target_planet = closest_empty_planets[0]
            if ship.can_dock(target_planet):
                command_queue.append(ship.dock(target_planet))
            else:
                navigate_command = ship.navigate(
                                    ship.closest_point_to(target_planet),
                                    game_map,
                                    speed = int(hlt.constants.MAX_SPEED),
                                    ignore_ships = False)
                #We can blow up to a planet by navigating to the center instead of the closest point to the planet
                if navigate_command:
                    command_queue.append(navigate_command)
        # FIND SHIP TO ATTACK!
        elif len(closest_empty_ships) > 0:
            target_ships = closest_empty_ships[0]
            navigate_command = ship.navigate(
                    ship.closest_point_to(target_ships),
                    game_map,
                    speed = int(hlt.constants.MAX_SPEED),
                    ignore_ships = False)
            #We can blow up to a planet by navigating to the center instead of the closest point to the planet
            if navigate_command:
                command_queue.append(navigate_command)

    # Send our set of commands to the Halite engine for this turn
    game.send_command_queue(command_queue)
    # TURN END
# GAME END
