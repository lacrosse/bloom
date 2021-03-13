defmodule Bloom.Repo do
  use Ecto.Repo, otp_app: :bloom, adapter: Sqlite.Ecto2
end
