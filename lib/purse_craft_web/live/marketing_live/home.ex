defmodule PurseCraftWeb.MarketingLive.Home do
  @moduledoc false

  use PurseCraftWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.marketing flash={@flash} current_scope={@current_scope}>
      <!-- Hero Section -->
      <section class="py-16 md:py-24 px-4">
        <div class="container mx-auto text-center">
          <h1 class="text-4xl md:text-6xl font-bold mb-6">Easy to use budgeting that works</h1>
          <p class="text-xl md:text-2xl mb-8 max-w-3xl mx-auto text-base-content/80">
            Take control of your finances with a simple, intuitive budgeting app designed to help you save more and stress less.
          </p>
          <div class="flex flex-col md:flex-row gap-4 justify-center">
            <%= if @current_scope do %>
              <.link href={~p"/books"} class="btn btn-primary btn-lg">Go to App</.link>
            <% else %>
              <.link href={~p"/users/register"} class="btn btn-primary btn-lg">Start your free trial</.link>
            <% end %>

            <a href="/how-it-works" class="btn btn-outline btn-lg">See how it works</a>
          </div>
        </div>
      </section>
      
    <!-- Features Section -->
      <section class="py-16 bg-base-200 px-4">
        <div class="container mx-auto">
          <h2 class="text-3xl md:text-4xl font-bold mb-12 text-center">
            Features designed for your financial success
          </h2>

          <div class="grid md:grid-cols-3 gap-8">
            <div class="card bg-base-100 shadow-md">
              <div class="card-body">
                <div class="mb-4 text-primary">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-10 h-10"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z"
                    />
                  </svg>
                </div>
                <h3 class="text-xl font-bold mb-2">Envelope Budgeting</h3>
                <p class="text-base-content/70">
                  Allocate your money to specific categories before you spend it, ensuring you always know where your money is going.
                </p>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md">
              <div class="card-body">
                <div class="mb-4 text-primary">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-10 h-10"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z"
                    />
                  </svg>
                </div>
                <h3 class="text-xl font-bold mb-2">Insightful Reports</h3>
                <p class="text-base-content/70">
                  Track your spending patterns and financial progress with clear, easy-to-understand reports and visualizations.
                </p>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md">
              <div class="card-body">
                <div class="mb-4 text-primary">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-10 h-10"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                    />
                  </svg>
                </div>
                <h3 class="text-xl font-bold mb-2">Monthly Planning</h3>
                <p class="text-base-content/70">
                  Plan ahead for expenses and set realistic goals with our monthly budgeting tools and forecasting features.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
      
    <!-- Pricing Section -->
      <section id="pricing" class="py-16 px-4">
        <div class="container mx-auto">
          <h2 class="text-3xl md:text-4xl font-bold mb-4 text-center">Simple, transparent pricing</h2>
          <p class="text-xl mb-12 text-center max-w-2xl mx-auto text-base-content/80">
            No hidden fees, no complicated tiers. Just one affordable plan for complete financial control.
          </p>

          <div class="max-w-md mx-auto">
            <div class="card bg-base-100 shadow-lg">
              <div class="card-body text-center">
                <h3 class="text-2xl font-bold">PurseCraft Premium</h3>
                <div class="my-4">
                  <span class="text-4xl font-bold">$5</span>
                  <span class="text-base-content/70">/month</span>
                </div>
                <ul class="mb-6 space-y-2">
                  <li class="flex items-center gap-2 justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5 text-success"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Unlimited budgets
                  </li>
                  <li class="flex items-center gap-2 justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5 text-success"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Advanced reporting
                  </li>
                  <li class="flex items-center gap-2 justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5 text-success"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Multiple accounts
                  </li>
                  <li class="flex items-center gap-2 justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5 text-success"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Data export
                  </li>
                  <li class="flex items-center gap-2 justify-center">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="w-5 h-5 text-success"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    Premium support
                  </li>
                </ul>
                <%= if @current_scope do %>
                  <.link href={~p"/books"} class="btn btn-primary btn-lg">Go to App</.link>
                <% else %>
                  <.link href={~p"/users/register"} class="btn btn-primary btn-lg">Start your free trial</.link>
                <% end %>

                <p class="text-sm mt-4 text-base-content/70">
                  30-day free trial, no credit card required
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.marketing>
    """
  end
end
