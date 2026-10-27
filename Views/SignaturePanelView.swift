//  SignaturePanelView.swift
//  侧栏「签名」面板：列出文档所有数字签名 + 验证状态，点击查看属性。

import SwiftUI

struct SignaturePanelView: View {
    @EnvironmentObject var vm: PDFEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            if vm.documentSignatures.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("暂无签名")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.documentSignatures) { sig in
                    SignatureRow(sig: sig)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.selectedSignature = sig
                            vm.sigPropPresented = true
                        }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

private struct SignatureRow: View {
    let sig: DocumentSignature

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: sig.valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(sig.valid ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(sig.signerName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Text(sig.signingTime)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 3)
    }
}
