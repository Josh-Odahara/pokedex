defmodule Pokedex.PokedexTest do
  use Pokedex.DataCase

  alias Pokedex.Pokedex

  describe "pokemon" do

    defp pokemon_fixture(attrs \\ %{}) do
      {:ok, pokemon} =
      attrs
      |> Enum.into(%{
        number: 1,
        name: "Bulbasaur",
        type: "Grass",
        hp: 45,
        attack: 49,
        defense: 49,
        speed: 45,
        shiny: false
      })
      |> Pokedex.create_pokemon()

      pokemon
    end

    test "list_pokemon/0 returns all pokemon" do
      pokemon= pokemon_fixture()
      assert Pokedex.list_pokemon() == [pokemon]
    end

    test "get_pokemon/1 returns the pokemon with given id" do
      pokemon = pokemon_fixture()
      assert Pokedex.get_pokemon(pokemon.id) == pokemon
    end

    test "create_pokemon/1 with valid data creates a pokemon" do
      assert {:ok, pokemon} = Pokedex.create_pokemon(%{
        number: 4,
        name: "Charmander",
        type: "Fire",
        hp: 39,
        attack: 52,
        defense: 43,
        speed: 65,
        shiny: false
      })
      assert pokemon.name == "Charmander"
      assert pokemon.type == "Fire"
    end

    test "delete_poke/1 deletes the pokemon" do
      pokemon = pokemon_fixture()
      assert {:ok, _} = Pokedex.delete_pokemon(pokemon)
      assert_raise Ecto.NoResultsError, fn -> Pokedex.get_pokemon(pokemon.id) end
    end

  end
end
