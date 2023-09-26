defmodule DisplayGeodataApi.Schemas.Token do

  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :token, :string

    timestamps()
  end

  def changeset(token, params \\ %{}) do
    token
    |> cast(params, [:token])
    |> validate_required([:token])
  end

end
