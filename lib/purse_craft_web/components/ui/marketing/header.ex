defmodule PurseCraftWeb.Components.UI.Marketing.Header do
  @moduledoc false

  use PurseCraftWeb, :html
  use Gettext, backend: PurseCraftWeb.Gettext

  alias PurseCraftWeb.Layouts

  def header(assigns) do
    ~H"""
    <header class="sticky top-0 z-30 bg-base-100 shadow-sm">
      <div class="container mx-auto flex justify-between items-center p-4">
        <div class="flex items-center">
          <.link href={~p"/"} class="text-2xl font-bold flex items-center gap-2">
            <span class="text-primary">PurseCraft</span>
          </.link>
        </div>

        <nav class="hidden md:flex items-center gap-8">
          <div class="dropdown">
            <button tabindex="0" role="button" class="flex items-center gap-1">
              Why PurseCraft
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-4 h-4"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
              </svg>
            </button>
            <div
              tabindex="0"
              class="dropdown-content z-50 card card-compact w-64 p-2 shadow bg-base-100"
            >
              <div class="card-body">
                <a href="/" class="block py-2 hover:text-primary">
                  <div class="font-semibold">Features</div>
                  <div class="text-sm text-base-content/70">
                    See how PurseCraft can help you budget better
                  </div>
                </a>
                <a href="/" class="block py-2 hover:text-primary">
                  <div class="font-semibold">About Us</div>
                  <div class="text-sm text-base-content/70">
                    Learn about our mission to make budgeting simple
                  </div>
                </a>
              </div>
            </div>
          </div>

          <div class="dropdown">
            <button tabindex="0" role="button" class="flex items-center gap-1">
              Community
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-4 h-4"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
              </svg>
            </button>
            <div
              tabindex="0"
              class="dropdown-content z-50 card card-compact w-64 p-2 shadow bg-base-100"
            >
              <div class="card-body">
                <a href="/" class="block py-2 hover:text-primary">
                  <div class="font-semibold">Blog</div>
                  <div class="text-sm text-base-content/70">
                    Articles about personal finance and budgeting
                  </div>
                </a>
                <a href="/" class="block py-2 hover:text-primary">
                  <div class="font-semibold">Documentation</div>
                  <div class="text-sm text-base-content/70">
                    Everything you need to get started with PurseCraft
                  </div>
                </a>
                <a href="https://github.com/pursecraft/pursecraft" class="block py-2 hover:text-primary">
                  <div class="font-semibold">GitHub</div>
                  <div class="text-sm text-base-content/70">
                    Follow our development and contribute
                  </div>
                </a>
              </div>
            </div>
          </div>

          <a href="#pricing" class="hover:text-primary">Pricing</a>
        </nav>
        
    <!-- Desktop user controls -->
        <div class="hidden md:flex items-center gap-4">
          <Layouts.theme_toggle />
          <%= if @current_scope do %>
            <!-- User dropdown -->
            <div class="dropdown dropdown-end">
              <label tabindex="0" class="btn btn-ghost btn-circle">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-10 flex items-center justify-center">
                    <span class="transform translate-y-0">
                      {String.at(@current_scope.user.email, 0) |> String.capitalize()}
                    </span>
                  </div>
                </div>
              </label>
              <ul
                tabindex="0"
                class="menu dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52 z-30"
              >
                <li>
                  <.link href={~p"/users/settings"}>Settings</.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete">Log out</.link>
                </li>
              </ul>
            </div>
            <.link href={~p"/books"} class="btn btn-primary">Go to App</.link>
          <% else %>
            <.link href={~p"/users/log-in"} class="hover:text-primary">Log in</.link>
            <.link href={~p"/users/register"} class="btn btn-primary">Start Free Trial</.link>
          <% end %>
        </div>
        
    <!-- Mobile menu button -->
        <div class="md:hidden flex items-center">
          <%= if @current_scope do %>
            <.link href={~p"/books"} class="btn btn-primary btn-sm mr-2">App</.link>
          <% end %>
          <button class="btn btn-ghost btn-sm btn-square" phx-click={JS.toggle(to: "#mobile-menu")}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-6 h-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>
        </div>
      </div>
      
    <!-- Mobile menu using DaisyUI components -->
      <div id="mobile-menu" class="hidden md:hidden bg-base-100 border-t">
        <!-- Mobile navigation using DaisyUI Collapse/Accordion -->
        <div>
          <div class="collapse collapse-arrow border-b">
            <input type="checkbox" />
            <div class="collapse-title font-medium">Why PurseCraft</div>
            <div class="collapse-content">
              <a href="/" class="block py-2 hover:text-primary">
                <div class="font-semibold">Features</div>
                <div class="text-sm text-base-content/70">
                  See how PurseCraft can help you budget better
                </div>
              </a>
              <a href="/" class="block py-2 hover:text-primary">
                <div class="font-semibold">About Us</div>
                <div class="text-sm text-base-content/70">
                  Learn about our mission to make budgeting simple
                </div>
              </a>
            </div>
          </div>

          <div class="collapse collapse-arrow border-b">
            <input type="checkbox" />
            <div class="collapse-title font-medium">Community</div>
            <div class="collapse-content">
              <a href="/" class="block py-2 hover:text-primary">
                <div class="font-semibold">Blog</div>
                <div class="text-sm text-base-content/70">
                  Articles about personal finance and budgeting
                </div>
              </a>
              <a href="/" class="block py-2 hover:text-primary">
                <div class="font-semibold">Documentation</div>
                <div class="text-sm text-base-content/70">
                  Everything you need to get started with PurseCraft
                </div>
              </a>
              <a href="https://github.com/pursecraft/pursecraft" class="block py-2 hover:text-primary">
                <div class="font-semibold">GitHub</div>
                <div class="text-sm text-base-content/70">Follow our development and contribute</div>
              </a>
            </div>
          </div>

          <div class="collapse border-b">
            <div class="collapse-title font-medium">
              <a href="#pricing" class="hover:text-primary">Pricing</a>
            </div>
          </div>
        </div>
        
    <!-- Theme toggle in mobile menu using DaisyUI layout -->
        <div class="flex justify-center p-4">
          <Layouts.theme_toggle />
        </div>
        
    <!-- User controls in mobile menu -->
        <%= if @current_scope do %>
          <div class="p-4 border-t">
            <div class="text-center font-medium mb-2">
              {@current_scope.user.email}
            </div>
            <div class="join join-vertical w-full">
              <.link href={~p"/users/settings"} class="btn join-item">Settings</.link>
              <.link href={~p"/users/log-out"} method="delete" class="btn btn-outline join-item">
                Log out
              </.link>
            </div>
          </div>
        <% else %>
          <div class="p-4 pt-0 border-t">
            <div class="join join-vertical w-full">
              <.link href={~p"/users/log-in"} class="btn btn-ghost join-item">Log in</.link>
              <.link href={~p"/users/register"} class="btn btn-primary join-item">
                Start Free Trial
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </header>
    """
  end
end
