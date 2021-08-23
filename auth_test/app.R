library(AzureAuth)
library(shiny)
library(shinyjs)

resource <- "00000003-0000-0000-c000-000000000000"
tenant <- "8fa8b681-571a-4377-966f-824fa460c7bf"
app <- "20769481-bc2e-497c-a46b-62ee1e8f7268"

# set this to the site URL of your app once it is deployed
# this must also be the redirect for your registered app in Azure Active Directory
redirect <- "http://localhost:8100"

options(shiny.port=as.numeric(httr::parse_url(redirect)$port))

# replace this with your app's regular UI
ui <- fluidPage(
    useShinyjs(),
    verbatimTextOutput("token")
)

ui_func <- function(req)
{
    opts <- parseQueryString(req$QUERY_STRING)
    if(is.null(opts$code))
    {
        auth_uri <- build_authorization_uri(resource, tenant, app, redirect_uri=redirect)
        redir_js <- sprintf("location.replace(\"%s\");", auth_uri)
        tags$script(HTML(redir_js))
    }
    else ui
}

# code for cleaning url after authentication
clean_url_js <- sprintf(
    "
    $(document).ready(function(event) {
      const nextURL = '%s';
      const nextTitle = 'My new page title';
      const nextState = { additionalInformation: 'Updated the URL with JS' };
      // This will create a new entry in the browser's history, without reloading
      window.history.pushState(nextState, nextTitle, nextURL);
    });
    ", redirect
)

server <- function(input, output, session)
{
    shinyjs::runjs(clean_url_js)
    
    opts <- parseQueryString(isolate(session$clientData$url_search))
    if(is.null(opts$code))
        return()
    
    # this assumes your app has a 'public client/native' redirect:
    # if it is a 'web' redirect, include the client secret as the password argument
    token <- get_azure_token(resource, tenant, app, auth_type="authorization_code",
                             authorize_args=list(redirect_uri=redirect),
                             use_cache=FALSE, auth_code=opts$code, 
                             token_args = list(given_name = "given_name", family_name = "family_name"))
    
    output$token <- renderPrint(token)
}

shinyApp(ui_func, server)