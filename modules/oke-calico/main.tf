# os namespace
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

data "kubectl_path_documents" "this" {
  pattern = "${path.module}/templates/calico-${var.calico_version}.yaml"
  vars = {
    image_registry = "${var.region}.ocir.io/${data.oci_objectstorage_namespace.this.namespace}/dtx"
  }
}

resource "kubectl_manifest" "this" {
  count     = length(data.kubectl_path_documents.this.documents)
  yaml_body = element(data.kubectl_path_documents.this.documents, count.index)
}
