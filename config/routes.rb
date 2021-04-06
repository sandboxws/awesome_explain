AwesomeExplain::Engine.routes.draw do
  get "/", to: "dashboard#index"
  get "/logs", to: "dashboard#logs"
  get "/logs/:id", to: "dashboard#log"
  get "/explains", to: "dashboard#explains"
  get "/stacktraces", to: "dashboard#stacktraces"
  get "/controllers", to: "dashboard#controllers"
  get "/controllers/:id", to: "dashboard#controller"
  get "/controllers/:id/sessions", to: "dashboard#sessions"
  get "/controllers/:id/sessions/:id", to: "dashboard#session"
end
