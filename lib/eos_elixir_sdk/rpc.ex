defmodule EosElixirSdk.Rpc do
  use Tesla

  def get_info do
    call(:get_info, %{})
  end

  def get_account(account_name) do
    body = %{"account_name" => account_name}
    call(:get_account, body)
  end

  def get_block(block_num) do
    body = %{"block_num_or_id" => block_num}
    call(:get_block, body)
  end

  def get_transaction(txid, block_num_hint \\ nil) do
    body = %{"id" => txid, "block_num_hint" => block_num_hint}
    call(:get_transaction, body)
  end

  def get_table_rows(code, scope, table, limit) do
    body = %{"code" => code, "scope" => scope, "table" => table, "json" => true, "limit" => limit}
    call(:get_table_rows, body)
  end

  def push_transaction(raw_transaction) do
    body = Jason.decode!(raw_transaction)
    call(:push_transaction, body)
  end

  # todo http request, response handle

  defp call(method, body) do
    headers = [{"accpet", "application/json"}, {"content-type", "application/json"}]

    with %{endpoint: endpoint} <-
           :eos_elixir_sdk |> Application.get_env(:rpc) |> Keyword.get(:conn),
         url = build_url(endpoint, method),
         {:ok, %{body: body}} <- post(url, Jason.encode!(body), headers),
         {:ok, %{} = body} <- Jason.decode(body) do
      {:ok, body}
    else
      {:ok, %{"code" => 500, "error" => error}} -> handle_error(error)
    end
  end

  defp build_url(endpoint, method) when method in [:get_transaction, :get_actions],
    do: endpoint <> "/v1/history/#{method}"

  defp build_url(endpoint, method), do: endpoint <> "/v1/chain/#{method}"

  defp handle_error(%{"code" => 3_040_005, "name" => "expired_tx_exception"}),
    do: {:error, :expired_tx_exception}

  defp handle_error({:error, %Jason.DecodeError{}}), do: {:error, :json_decode_error}
  defp handle_error({:error, :socket_closed_remotely}), do: {:error, :socket_closed_remotely}
  defp handle_error(error), do: "#{inspect(error)}"
end
