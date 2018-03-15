import os
import time

ship_requirement = 10
damage_requirement = 1000


def get_ships(data):
    return int(data.split("producing ")[1].split(" ships")[0])

def get_damage(data):
    return int(data.split("dealing ")[1].split(" damage")[0])

def get_rank(data):
    return int(data.split("rank #")[1].split(" and")[0])

player_1_wins = 0
player_2_wins = 0

for num in range(5000):
    try:
        print("Currently on: {}".format(num))
        if player_1_wins > 0 or player_2_wins > 0:
            p1_pct = round(player_1_wins/(player_1_wins+player_2_wins)*100.0, 2)
            p2_pct = round(player_2_wins/(player_1_wins+player_2_wins)*100.0, 2)
            print("Player 1 win: {}%; Player 2 win: {}%.".format(p1_pct, p2_pct))

        os.system('halite.exe -d "360 240" "python MyBot-1.py" "python MyBot-2.py" >> data.gameout')

        with open('data.gameout', 'r') as f:
            contents = f.readlines()
            CharlesBot1 = contents[-4]
            CharlesBot2 = contents[-3]
            print(CharlesBot1)
            print(CharlesBot2)

            CharlesBot1_ships = get_ships(CharlesBot1)
            CharlesBot1_dmg = get_damage(CharlesBot1)
            CharlesBot1_rank = get_rank(CharlesBot1)

            CharlesBot2_ships = get_ships(CharlesBot2)
            CharlesBot2_dmg = get_damage(CharlesBot2)
            CharlesBot2_rank = get_rank(CharlesBot2)

            print("Charles1 rank: {} ships: {} dmg: {}".format(CharlesBot1_rank,CharlesBot1_ships,CharlesBot1_dmg))
            print("Charles2 rank: {} ships: {} dmg: {}".format(CharlesBot2_rank,CharlesBot2_ships,CharlesBot2_dmg))

        if CharlesBot1_rank == 1:
            print("c1 won")
            player_1_wins += 1
            if CharlesBot1_ships >= ship_requirement and CharlesBot1_dmg >= damage_requirement:
                with open("c1_input.vec","r") as f:
                    input_lines = f.readlines()
                with open("train.in","a") as f:
                    for l in input_lines:
                        f.write(l)

                with open("c1_out.vec","r") as f:
                    output_lines = f.readlines()
                with open("train.out","a") as f:
                    for l in output_lines:
                        f.write(l)

        elif CharlesBot2_rank == 1:
            print("c2 won")
            player_2_wins += 1
            if CharlesBot2_ships >= ship_requirement and CharlesBot2_dmg >= damage_requirement:
                with open("c2_input.vec","r") as f:
                    input_lines = f.readlines()
                with open("train.in","a") as f:
                    for l in input_lines:
                        f.write(l)
                    
                with open("c2_out.vec","r") as f:
                    output_lines = f.readlines()
                with open("train.out","a") as f:
                    for l in output_lines:
                        f.write(l)

        time.sleep(2)
    except Exception as e:
        print(str(e))
        time.sleep(2)
