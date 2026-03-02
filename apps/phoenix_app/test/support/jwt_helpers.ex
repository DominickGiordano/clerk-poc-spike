defmodule PhoenixAppWeb.JwtHelpers do
  @moduledoc """
  Test helpers for generating RS256 JWTs with a known key pair.
  Uses :crypto to generate keys — no Clerk instance needed.
  """

  @doc """
  Generates a fresh RS256 key pair and returns {private_key, public_key_pem}.
  """
  def generate_rsa_key_pair do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})

    public_key =
      case private_key do
        {:RSAPrivateKey, _, modulus, public_exponent, _, _, _, _, _, _, _} ->
          {:RSAPublicKey, modulus, public_exponent}
      end

    public_pem_entry = :public_key.pem_entry_encode(:SubjectPublicKeyInfo, public_key)
    public_pem = :public_key.pem_encode([public_pem_entry])

    {private_key, public_pem}
  end

  @doc """
  Signs a JWT with the given claims using the private key.
  """
  def sign_jwt(claims, private_key) do
    signer = Joken.Signer.create("RS256", %{"pem" => private_key_to_pem(private_key)})
    {:ok, token, _claims} = Joken.generate_and_sign(%{}, claims, signer)
    token
  end

  defp private_key_to_pem(private_key) do
    pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, private_key)
    :public_key.pem_encode([pem_entry])
  end

  @doc """
  Returns standard Clerk-like claims for a test user.
  """
  def valid_claims(overrides \\ %{}) do
    now = System.system_time(:second)

    Map.merge(
      %{
        "sub" => "user_test123",
        "email" => "test@example.com",
        "exp" => now + 3600,
        "nbf" => now - 60,
        "iat" => now - 60
      },
      overrides
    )
  end
end
