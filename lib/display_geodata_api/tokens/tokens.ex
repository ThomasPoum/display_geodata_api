defmodule DisplayGeodataApi.Tokens.Tokens do
  alias DisplayGeodataApi.Schemas.Token
  alias DisplayGeodataApi.Repo
  import Ecto.Query

  def create_token(attrs \\ %{}) do
    %Token{}
    |> Token.changeset(attrs)
    |> Repo.insert()
  end

  def get_token_by_value(token_value) do
    Repo.get_by(Tokens, token: token_value)
  end

  def delete_token(token) do
    Repo.delete(token)
  end

  def token_exists?(token) do
    query =
      from(t in Token,
        where: t.token == ^token,
        select: true
      )

    Repo.exists?(query)
  end

  def validate_token(token_value) do
    if token_exists?(token_value) do
      {:ok}
    else
      {:unauthorized}
    end
  end
end
