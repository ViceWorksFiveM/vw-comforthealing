# vw-comforthealing

**vw-comforthealing** is a FiveM script that dynamically adjusts player health regeneration based on comfort, hunger, thirst, and nearby fires or players. The system calculates comfort levels depending on environmental factors and regenerates health when specific conditions are met.

## Features

- Health regeneration based on player's **comfort** level.
- **Comfort** affected by nearby fires, player position (sitting or standing), and proximity to other players.
- Hunger and thirst values influence the health regeneration process.
- Supports bleeding checks via **qb-core** hospital callback.
- Configurable comfort radius and regeneration rates.
- Debugging options available to monitor health, comfort, hunger, and thirst in real-time.

## Requirements

- **qb-core** framework. (optional)
  
## Installation

1. Download or clone the repository to your `resources` folder.
2. Add the script to your `server.cfg`: `ensure vw-comforthealing`
3. Configure the script in `config.lua` according to your server needs.

## Usage

The script continuously checks comfort levels and dynamically adjusts health regeneration. If the player is near a fire, sitting, or has other players nearby, comfort levels increase. Hunger, thirst, and bleeding conditions also affect regeneration.

### Commands

- `/plyhl`: Resets the player's health for testing purposes (debug only).

## Configuration

You can adjust the following parameters in `config.lua`:

- `comfortRadius`: Defines how close players need to be to fire or other players for comfort increase.
- `comfortIncreaseRate`: Rate at which comfort increases when conditions are met.
- `comfortDecreaseRate`: Rate at which comfort decreases when no comfort sources are present.
- `maxRegenRate`: Maximum possible health regeneration rate.
- `metabolismInterval`: Time interval in milliseconds between comfort and metabolism calculations.

## Contributing

Feel free to submit issues or contribute to the project by opening a pull request on GitHub.

## License

This project is licensed under the MIT License.
