const DEFAULT_ENERGY = 50
const DEFAULT_CELL = 1
const NONE = -1
const MONSTER_INITIAL_CELL = 7
const MONSTER_ENERGY = 2000

@enum ObjectType health weapon trap

struct Cell
  north::Int32
  south::Int32
  east::Int32
  west::Int32
  up::Int32
  down::Int32
  object::Int32
  hasTreasure::Bool
  isDefault::Bool
  description::String
end

mutable struct Player
  name::String
  energy::Int32
  cell::Cell
  carriedObject::Int32
  carriesTreasure::Bool
end

mutable struct Monster
  energy::Int32
  cell::Cell
end

struct Object
  name::String
  energy::Int32
  type::ObjectType
  id::Int32
  trapDescription::String
end

mutable struct Game
  player::Player
  monster::Monster
  cells::Array{Cell}
  objects::Array{Object}
  monsterDead::Bool
  lock::ReentrantLock
end

function initialize_cells()::Array{Cell}
  cells::Array{Cell} = []

  push!(cells, Cell(
    NONE,
    NONE,
    2,
    NONE,
    NONE,
    NONE,
    NONE,
    false,
    true,
    "You're in front of a big castle. \
      You hear strange noises coming from inside."
  ))

  push!(cells, Cell(
    4,
    5,
    3,
    1,
    NONE,
    6,
    NONE,
    false,
    false,
    "You're at the castle's hall. \
      You see a lot of doors and stairs that seem to go down."
  ))

  push!(cells, Cell(
    NONE,
    NONE,
    NONE,
    2,
    7,
    NONE,
    NONE,
    false,
    false,
    "You see very long stairs that seem to go up."
  ))

  push!(cells, Cell(
    NONE,
    2,
    NONE,
    NONE,
    NONE,
    NONE,
    1,
    false,
    false,
    "You're in a small room with a chest in the center."
  ))

  push!(cells, Cell(
    2,
    NONE,
    NONE,
    NONE,
    NONE,
    8,
    NONE,
    false,
    false,
    "A very, very dark set of stairs goes down, deep underground. \
      I wouldn't go there."
  ))

  push!(cells, Cell(
    NONE,
    NONE,
    9,
    NONE,
    2,
    NONE,
    NONE,
    false,
    false,
    "There's a very fancy door right in front of you."
  ))

  push!(cells, Cell(
    10,
    NONE,
    NONE,
    NONE,
    NONE,
    3,
    4,
    false,
    false,
    "You're at what seems to be the throne room."
  ))

  push!(cells, Cell(
    NONE,
    NONE,
    NONE,
    NONE,
    5,
    NONE,
    2,
    false,
    false,
    "Spikes hit you. It was a trap. You were warned."
  ))

  push!(cells, Cell(
    NONE,
    NONE,
    NONE,
    6,
    NONE,
    NONE,
    NONE,
    true,
    false,
    "You find a very good-looking treasure chest."
  ))

  push!(cells, Cell(
    NONE,
    7,
    NONE,
    NONE,
    NONE,
    NONE,
    3,
    false,
    false,
    "This seems to be the monster's storage room."
  ))

  return cells
end

function initialize_objects()::Array{Object}
  objects::Array{Object} = []

  push!(objects, Object(
    "Ancient Sword",
    40,
    weapon,
    1,
    ""
  ))

  push!(objects, Object(
    "Spikes",
    999999999,
    trap,
    2,
    "You got spiked to death."
  ))

  push!(objects, Object(
    "Honjo Masamune",
    150,
    weapon,
    3,
    ""
  ))

  push!(objects, Object(
    "Health Potion",
    450,
    health,
    4,
    ""
  ))

  return objects
end

function move_monster(monster::Monster, cells::Array{Cell})
  invalid = true
  direction = 0
  while invalid
    direction = rand(1:6)
    while direction == 1 && monster.cell.north == NONE ||
          direction == 2 && monster.cell.south == NONE ||
          direction == 3 && monster.cell.east == NONE ||
          direction == 4 && monster.cell.west == NONE ||
          direction == 5 && monster.cell.up == NONE ||
          direction == 6 && monster.cell.down == NONE
      direction = rand(1:6)
    end
    invalid = false
  end

  if direction == 1
    monster.cell = cells[monster.cell.north]
  elseif direction == 2
    monster.cell = cells[monster.cell.south]
  elseif direction == 3
    monster.cell = cells[monster.cell.east]
  elseif direction == 4
    monster.cell = cells[monster.cell.west]
  elseif direction == 5
    monster.cell = cells[monster.cell.up]
  elseif direction == 6
    monster.cell = cells[monster.cell.down]
  end

  if monster.cell.object == 1
    invalid = true
  else
    invalid = 0
  end
end

function player_thread(game::Game)
  (; cells, player, objects, monster) = game

  game_over = false
  found_objects = falses(length(objects))
  println("> " * cells[DEFAULT_CELL].description)
  while !game_over
    if game.monsterDead && player.carriesTreasure
      if player.cell.isDefault
        println("You escaped!")
        break
      end

      println("!!! You are now ready to leave to complete your mission.")
    end

    println("You have " * string(player.energy) * " energy.")
    input_invalid = true
    while input_invalid
      input_invalid = false
      possible_moves = ""
      if player.cell.north != NONE
        possible_moves *= "(n)orth,"
      end
      if player.cell.south != NONE
        possible_moves *= "(s)outh,"
      end
      if player.cell.east != NONE
        possible_moves *= "(e)ast,"
      end
      if player.cell.west != NONE
        possible_moves *= "(w)est,"
      end
      if player.cell.up != NONE
        possible_moves *= "(u)p,"
      end
      if player.cell.down != NONE
        possible_moves *= "(d)own,"
      end

      possible_moves = chop(possible_moves)
      print("Where do you want to go? (" * possible_moves * ") ")
      input = readline()

      if cmp(input, "n") == 0 && player.cell.north != NONE
        player.cell = cells[player.cell.north]
      elseif cmp(input, "s") == 0 && player.cell.south != NONE
        player.cell = cells[player.cell.south]
      elseif cmp(input, "e") == 0 && player.cell.east != NONE
        player.cell = cells[player.cell.east]
      elseif cmp(input, "w") == 0 && player.cell.west != NONE
        player.cell = cells[player.cell.west]
      elseif cmp(input, "u") == 0 && player.cell.up != NONE
        player.cell = cells[player.cell.up]
      elseif cmp(input, "d") == 0 && player.cell.down != NONE
        player.cell = cells[player.cell.down]
      else
        println("Invalid input. Try again.")
        input_invalid = true
      end
    end

    if player.cell.object != NONE
      found = objects[player.cell.object]
      println("Found an object")
      if found.type == weapon && !found_objects[found.id]
        print("You found a " * found.name * "! It deals "
          * string(found.energy) * " energy. Do you want to pick \
          it up? (y/n) ")
        input = readline()
        if cmp(input, "y") == 0
          found_objects[found.id] = true
          println("You now own this " * found.name * "!")
          player.carriedObject = found.id
        end
      elseif found.type == trap
        println(found.trapDescription)
        player.energy -= found.energy
        if player.energy <= 0
          println("You died!")
          break
        end
      elseif found.type == health && !found_objects[found.id]
        println("You found a " * found.name * "! Your energy \
          increased by " * string(found.energy) * ".")
        player.energy += found.energy
        found_objects[found.id] = true
      end
    elseif player.cell.hasTreasure
      println("You found the treasure!")
      if game.monsterDead
        println("You can escape now.")
      else
        println("Defeat the monster and escape.")
      end

      player.carriesTreasure = true
    end

    println("> " * player.cell.description)

    if player.cell == monster.cell
      println("You met the monster! It's time to fight!")
      while !game.monsterDead
        print("What to do? ((w)eak attack,(s)trong attack,(r)un away) ")
        input = readline()
        if cmp(input, "w") == 0 || cmp(input, "s") == 0
          maxDealtEnergy = player.carriedObject != NONE ?
            objects[player.carriedObject].energy : 10
          failAttack = rand(0:1) == 0
          dealtEnergy = (cmp(input, "w") == 0) ?
            rand(1:(maxDealtEnergy - 5)) :
            rand(1:(maxDealtEnergy + 200))
          
          # Only fail if it's a strong attack.
          if failAttack && cmp(input, "s") == 0
            println("You missed.")
          else
            monster.energy -= dealtEnergy
            println("You dealt " * string(dealtEnergy) * " to the monster! \
              The monster now has " * string(monster.energy) * " energy.")
          end

          if monster.energy <= 0
            lock(game.lock)
            game.monsterDead = true
            unlock(game.lock)
          else
            failAttack = rand(0:1) == 0
            if failAttack
              println("The monster missed.")
              continue
            end

            dealtEnergy = rand(1:50)
            player.energy -= dealtEnergy
            println("The monster dealt " * string(dealtEnergy) * " to you! \
              You now have " * string(player.energy) * " energy.")
            if player.energy <= 0
              game_over = true
              println("You died!")
              break
            end
          end
        else
          println("You ran away!")
          break
        end
      end

      if game.monsterDead
        println("You killed the monster! Congratulations!")
      else
        println("The monster's energy is now " * string(monster.energy) * ".")
      end
    end
  end

  println("Game over!")
end

function monster_thread(game::Game)
  while !game.monsterDead && game.player.energy > 0
    sleep(5)
    lock(game.lock)
    move_monster(game.monster, game.cells)
    unlock(game.lock)
  end
end

println("Welcome to Aventure Game v0.0.2 Julia Edition.")
println("The objective is to defeat the monster and steal the treasure. Good luck!")
print("What is your name? ")
name = readline()

cells = initialize_cells()
objects = initialize_objects()
player = Player(name, DEFAULT_ENERGY, cells[DEFAULT_CELL], NONE, false)
monster = Monster(MONSTER_ENERGY, cells[MONSTER_INITIAL_CELL])

game = Game(player, monster, cells, objects, false, ReentrantLock())

task1 = Threads.@spawn player_thread(game)
task2 = Threads.@spawn monster_thread(game)

wait(task1)
wait(task2)
