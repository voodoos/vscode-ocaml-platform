open Vscode
module LanguageClient = Vscode_languageclient.LanguageClient

(* Path of the LSP server worker bundle, relative to the extension root. The
   worker is loaded as a static asset at runtime via the [Worker] global. *)
let worker_relative_path = [ "dist"; "merlin_lsp_worker.bc.js" ]

let make_worker ~url =
  let worker_ctor = Ojs.get_prop_ascii Ojs.global "Worker" in
  Ojs.new_obj worker_ctor [| Ojs.string_to_js url |]
;;

let activate (extension : ExtensionContext.t) =
  let documentSelector =
    Vscode_languageclient.DocumentSelector.
      [| language "ocaml"
       ; language "ocaml.interface"
       ; language "ocaml.ocamllex"
       ; language "ocaml.menhir"
       ; language "ocaml.mlx"
       ; language "reason"
      |]
  in
  let outputChannel = Window.createOutputChannel ~name:"OCaml Language Server" () in
  let clientOptions =
    Vscode_languageclient.ClientOptions.create
      ~outputChannel
      ~revealOutputChannelOn:Vscode_languageclient.RevealOutputChannelOn.Never
      ~documentSelector
      ()
  in
  let worker_uri =
    Uri.joinPath
      (ExtensionContext.extensionUri extension)
      ~pathSegments:worker_relative_path
  in
  let worker = make_worker ~url:(Uri.toString worker_uri ()) in
  let client =
    LanguageClient.make_browser
      ~id:"ocaml"
      ~name:"OCaml Platform VS Code extension"
      ~clientOptions
      ~worker
      ()
  in
  let (_ : unit Promise.t) = LanguageClient.start client in
  ExtensionContext.subscribe
    extension
    ~disposable:
      (Disposable.make ~dispose:(fun () ->
         let (_ : unit Promise.t) = LanguageClient.stop client in
         ()));
  Promise.return ()
;;

let () =
  let open Js_of_ocaml.Js in
  export "activate" (wrap_callback activate)
;;
