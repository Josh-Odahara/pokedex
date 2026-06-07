defmodule PokedexWeb.PokemonLive do
  use PokedexWeb, :live_view
  alias Pokedex.Pokedex
  alias Pokedex.CSVParser

  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(
        active_tab: :upload,
        preview_data: [],
        loading: false,
        pokemon: Pokedex.list_pokemon(),
        editing_pokemon: nil,
        search: ""
      )
      |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1)
    }
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_atom(tab))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import_csv", _params, socket) do
    preview = consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
      contents = File.read!(path)
      {:ok, Pokedex.parse_csv(contents)}
    end)
    |> List.flatten()

    {:noreply, assign(socket, preview_data: preview)}
  end

  def handle_event("confirm_import", _params, socket) do
    socket = assign(socket, loading: true)
    Enum.each(socket.assigns.preview_data, fn pokemon ->
      Pokedex.create_pokemon(pokemon)
    end)

    {:noreply, assign(socket, loading: false, preview_data: [], active_tab: :browse, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("delete_pokemon", %{"id" => id}, socket) do
    id = String.to_integer(id)
    pokemon = Pokedex.get_pokemon(id)
    Pokedex.delete_pokemon(pokemon)
    {:noreply, assign(socket, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("edit_pokemon", %{"id" => id}, socket) do
    id = String.to_integer(id)
    pokemon = Pokedex.get_pokemon(id)
    {:noreply, assign(socket, editing_pokemon: pokemon)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_pokemon: nil)}
  end

  def handle_event("update_pokemon", params, socket) do
    id = String.to_integer(params["id"])
    pokemon = Pokedex.get_pokemon(id)
    Pokedex.update_pokemon(pokemon, params)
    {:noreply, assign(socket, editing_pokemon: nil, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("search", %{"search" => search_value}, socket) do
    {:noreply, assign(socket, search: search_value)}
  end

  defp filter_pokemon(pokemon_list, ""), do: pokemon_list
  defp filter_pokemon(pokemon_list, search) do
    Enum.filter(pokemon_list, fn pokemon -> String.contains?(String.downcase(pokemon.name), String.downcase(search)) end)
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-1000 text-white p-8">
      <h1 class="text-4xl font-bold text-red-500 mb-8">Pokedex</h1>

      <div class="flex gap-4 mb-8">
        <button
          phx-click="switch_tab"
          phx-value-tab="upload"
          class={if @active_tab == :upload, do: "px-6 py-2 rounded-full font-semibold bg-red-500 text-white", else: "px-6 py-2 rounded-full font-semibold bg-gray-700 text-white hover:bg-gray-600"}>
          Upload
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="browse"
          class={if @active_tab == :browse, do: "px-6 py-2 rounded-full font-semibold bg-red-500 text-white", else: "px-6 py-2 rounded-full font-semibold bg-gray-700 text-white hover:bg-gray-600"}>
          Browse
        </button>
      </div>

      <div :if={@active_tab == :upload}>
        Upload here
        <form phx-change="validate" phx-submit="import_csv">
          <.live_file_input upload={@uploads.csv} />
          <button type="submit">Preview CSV</button>
          <table>
            <thead>
              <tr>
                <th>Number </th>
                <th>Name </th>
                <th>Nickname </th>
                <th>Type </th>
                <th>HP </th>
                <th>Attack </th>
                <th>Defense </th>
                <th>Speed </th>
                <th>Shiny </th>
              </tr>
            </thead>

            <tbody>
              <tr :for={pokemon <- @preview_data}>
                <td><%= pokemon.number %></td>
                <td><%= pokemon.name %></td>
                <td><%= pokemon.nickname %></td>
                <td><%= pokemon.type %></td>
                <td><%= pokemon.hp %></td>
                <td><%= pokemon.attack %></td>
                <td><%= pokemon.defense %></td>
                <td><%= pokemon.speed %></td>
                <td><%= pokemon.shiny %></td>
              </tr>
            </tbody>
          </table>

          <button :if={@preview_data != []} type="button" phx-click="confirm_import">Confirm Import</button>
          <div :if={@loading}>Loading...</div>
            </form>
          </div>

      <div :if={@active_tab == :browse}>
        <form phx-change="search">
          <input type="search" name="search" value={@search} placeholder="Search Pokemon" phx-change="search" />
        </form>

      <div :if={@editing_pokemon}>
        <h3>Editing <%= @editing_pokemon.name %></h3>
          <form phx-submit="update_pokemon">
            <input type="hidden" name="id" value={@editing_pokemon.id} />
            <input type="number" name="number" value={@editing_pokemon.number} />
            <input type="text" name="name" value={@editing_pokemon.name} />
            <input type="text" name="nickname" value={@editing_pokemon.nickname} />
            <input type="text" name="type" value={@editing_pokemon.type} />
            <input type="number" name="hp" value={@editing_pokemon.hp} />
            <input type="number" name="attack" value={@editing_pokemon.attack} />
            <input type="number" name="defense" value={@editing_pokemon.defense} />
            <input type="number" name="speed" value={@editing_pokemon.speed} />
            <input type="checkbox" name="shiny" checked={@editing_pokemon.shiny} />
            <button type="submit">Save</button>
            <button type="button" phx-click="cancel_edit">Cancel</button>
        </form>
      </div>

      <table>
          <thead>
            <tr>
              <th>Number </th>
              <th>Name </th>
              <th>Nickname </th>
              <th>Type </th>
              <th>HP </th>
              <th>Attack </th>
              <th>Defense </th>
              <th>Speed </th>
              <th>Shiny </th>
              <th>Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr :for={pokemon <- filter_pokemon(@pokemon, @search)}>
              <td><%= pokemon.number %></td>
              <td><%= pokemon.name %></td>
              <td><%= pokemon.nickname %></td>
              <td><%= pokemon.type %></td>
              <td><%= pokemon.hp %></td>
              <td><%= pokemon.attack %></td>
              <td><%= pokemon.defense %></td>
              <td><%= pokemon.speed %></td>
              <td><%= pokemon.shiny %></td>
              <td>
                <button phx-click="delete_pokemon" phx-value-id={pokemon.id}>Delete </button>
                <button phx-click="edit_pokemon" phx-value-id={pokemon.id}> Edit</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  """
  end
end
