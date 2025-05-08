from shiny import App, ui, render

app_ui = ui.page_fluid(
    ui.input_slider("n", "Number of bins", 10, 100, 20),
    ui.output_text_verbatim("txt")
)

def server(input, output, session):
    @output
    @render.text
    def txt():
        return f"Selected: {input.n()} bins"

app = App(app_ui, server)