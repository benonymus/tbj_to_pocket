import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tbj_to_pocket, TbjToPocketWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "PBjp5xwLKUA2Ddyiq+PQS7nGTrPSDsw51V3af87Q6wj/D0F6xXYVHoMjTONncRI9",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
