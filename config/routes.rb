AwesomeExplain::Engine.routes.draw do
  get "/", to: "dashboard#index"
  get "/logs", to: "dashboard#logs"
  get "/logs/:id", to: "dashboard#log"
  get "/explains", to: "dashboard#explains"
  get "/stacktraces", to: "dashboard#stacktraces"
end
