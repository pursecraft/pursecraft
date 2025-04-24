defmodule PurseCraftWeb.Components.UI.Marketing.Footer do
  @moduledoc false

  use PurseCraftWeb, :html
  use Gettext, backend: PurseCraftWeb.Gettext

  def footer(assigns) do
    ~H"""
    <footer class="bg-base-200 py-12 px-4">
      <div class="container mx-auto">
        <div class="grid md:grid-cols-4 gap-8">
          <div>
            <h3 class="text-lg font-bold mb-4">PurseCraft</h3>
            <p class="text-base-content/70">
              Take control of your finances with our simple, intuitive budgeting app.
            </p>
          </div>

          <div>
            <h3 class="text-lg font-bold mb-4">Product</h3>
            <ul class="space-y-2">
              <li><a href="/" class="hover:text-primary">Features</a></li>
              <li><a href="/" class="hover:text-primary">Pricing</a></li>
              <li><a href="/" class="hover:text-primary">Roadmap</a></li>
            </ul>
          </div>

          <div>
            <h3 class="text-lg font-bold mb-4">Resources</h3>
            <ul class="space-y-2">
              <li><a href="/" class="hover:text-primary">Blog</a></li>
              <li><a href="/" class="hover:text-primary">Documentation</a></li>
              <li><a href="/" class="hover:text-primary">Support</a></li>
            </ul>
          </div>

          <div>
            <h3 class="text-lg font-bold mb-4">Company</h3>
            <ul class="space-y-2">
              <li><a href="/" class="hover:text-primary">About Us</a></li>
              <li><a href="/" class="hover:text-primary">Contact</a></li>
              <li><a href="/" class="hover:text-primary">Privacy Policy</a></li>
            </ul>
          </div>
        </div>

        <div class="mt-12 pt-8 border-t border-base-300 flex flex-col md:flex-row justify-between items-center">
          <p>© {DateTime.utc_now().year} PurseCraft. All rights reserved.</p>
          <div class="flex gap-4 mt-4 md:mt-0">
            <a href="https://github.com/pursecraft/pursecraft" class="hover:text-primary">
              <span class="sr-only">GitHub</span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="w-5 h-5"
              >
                <path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4">
                </path>
                <path d="M9 18c-4.51 2-5-2-7-2"></path>
              </svg>
            </a>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
