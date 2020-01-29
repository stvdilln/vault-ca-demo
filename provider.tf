provider "vault" {
    # Since we have the vault server running with both SSL and non-ssl modes depending 
    # on the stage of the demo, I don't try to configure all of that here, but depend on 
    # environment variables to tell terraform how to talk to vault
}