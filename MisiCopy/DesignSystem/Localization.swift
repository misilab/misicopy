//
//  Localization.swift
//  MisiCopy
//
//  Centralized translations for FR / EN / ES.
//

import Foundation

struct Localization {
    let language: AppLanguage

    // MARK: - Locale-aware formatters

    /// Locale matching the user's language preference (FR/EN/ES) rather
    /// than the macOS system locale.
    var locale: Locale {
        switch language {
        case .fr: return Locale(identifier: "fr_FR")
        case .en: return Locale(identifier: "en_US")
        case .es: return Locale(identifier: "es_ES")
        }
    }

    /// Date+time formatter respecting the app language. Example outputs:
    ///   fr → "4 juin 2026 à 11:39"
    ///   en → "Jun 4, 2026 at 11:39 AM"
    ///   es → "4 jun 2026 11:39"
    func formatDateTime(_ date: Date, dateStyle: DateFormatter.Style = .medium,
                        timeStyle: DateFormatter.Style = .short) -> String {
        let f = DateFormatter()
        f.dateStyle = dateStyle
        f.timeStyle = timeStyle
        f.locale = locale
        return f.string(from: date)
    }

    func formatShortDateTime(_ date: Date) -> String {
        formatDateTime(date, dateStyle: .short, timeStyle: .short)
    }

    func formatLongDateTime(_ date: Date) -> String {
        formatDateTime(date, dateStyle: .long, timeStyle: .short)
    }

    // MARK: - Header
    var headerSubtitle: String {
        switch language {
        case .fr: return "Copie sécurisée avec vérification"
        case .en: return "Secure copy with verification"
        case .es: return "Copia segura con verificación"
        }
    }

    // MARK: - Sections
    var sectionMode: String {
        switch language {
        case .fr: return "Mode de copie"
        case .en: return "Copy mode"
        case .es: return "Modo de copia"
        }
    }
    var sectionSource: String {
        switch language {
        case .fr: return "Source"
        case .en: return "Source"
        case .es: return "Origen"
        }
    }
    var sectionDestinations: String {
        switch language {
        case .fr: return "Destinations"
        case .en: return "Destinations"
        case .es: return "Destinos"
        }
    }
    var sectionJournal: String {
        switch language {
        case .fr: return "Journal"
        case .en: return "Log"
        case .es: return "Registro"
        }
    }

    // MARK: - Modes
    func modeTitle(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Copie + vérification"
        case (.verified, .en): return "Copy + verification"
        case (.verified, .es): return "Copia + verificación"
        case (.doubleVerified, .fr): return "Copie + double vérification"
        case (.doubleVerified, .en): return "Copy + double verification"
        case (.doubleVerified, .es): return "Copia + doble verificación"
        case (.fast, .fr): return "Copie rapide"
        case (.fast, .en): return "Fast copy"
        case (.fast, .es): return "Copia rápida"
        case (.verifyOnly, .fr): return "Vérification seule"
        case (.verifyOnly, .en): return "Verify only"
        case (.verifyOnly, .es): return "Solo verificación"
        }
    }
    func modeVerificationDetail(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Hash source + hash destination → comparaison"
        case (.verified, .en): return "Source hash + destination hash → comparison"
        case (.verified, .es): return "Hash origen + hash destino → comparación"
        case (.doubleVerified, .fr): return "Hash source + dest + re-hash source (3 lectures)"
        case (.doubleVerified, .en): return "Source hash + dest + re-hash source (3 reads)"
        case (.doubleVerified, .es): return "Hash origen + dest + re-hash origen (3 lecturas)"
        case (.fast, .fr): return "Aucune vérification — copie seule"
        case (.fast, .en): return "No verification — copy only"
        case (.fast, .es): return "Sin verificación — solo copia"
        case (.verifyOnly, .fr): return "Hash source + hash de la copie existante → comparaison"
        case (.verifyOnly, .en): return "Source hash + existing copy hash → comparison"
        case (.verifyOnly, .es): return "Hash origen + hash de la copia existente → comparación"
        }
    }
    func modeSubtitle(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Checksum après copie — recommandé"
        case (.verified, .en): return "Checksum after copy — recommended"
        case (.verified, .es): return "Checksum tras la copia — recomendado"
        case (.doubleVerified, .fr): return "Re-lit la source et la destination pour comparer"
        case (.doubleVerified, .en): return "Re-reads source and destination to compare"
        case (.doubleVerified, .es): return "Vuelve a leer origen y destino para comparar"
        case (.fast, .fr): return "Sans vérification — déconseillé pour archive"
        case (.fast, .en): return "No verification — not recommended for archive"
        case (.fast, .es): return "Sin verificación — no recomendado para archivo"
        case (.verifyOnly, .fr): return "Compare source et copie existante — ne copie rien"
        case (.verifyOnly, .en): return "Compares source and existing copy — copies nothing"
        case (.verifyOnly, .es): return "Compara origen y copia existente — no copia nada"
        }
    }

    // MARK: - Toggles & picker
    var toggleSimulation: String {
        switch language {
        case .fr: return "Simulation (aucun fichier copié)"
        case .en: return "Simulation (no file copied)"
        case .es: return "Simulación (ningún archivo copiado)"
        }
    }
    var togglePreserve: String {
        switch language {
        case .fr: return "Préserver la structure"
        case .en: return "Preserve structure"
        case .es: return "Conservar estructura"
        }
    }
    var labelAlgorithm: String {
        switch language {
        case .fr: return "Algorithme"
        case .en: return "Algorithm"
        case .es: return "Algoritmo"
        }
    }
    var labelElapsed: String {
        switch language {
        case .fr: return "Écoulé"
        case .en: return "Elapsed"
        case .es: return "Transcurrido"
        }
    }
    var labelRemaining: String {
        switch language {
        case .fr: return "Restant"
        case .en: return "Remaining"
        case .es: return "Restante"
        }
    }

    // MARK: - Source & destinations
    var sourceEmptyTitle: String {
        switch language {
        case .fr: return "Aucun dossier sélectionné"
        case .en: return "No folder selected"
        case .es: return "Ninguna carpeta seleccionada"
        }
    }
    var sourceEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez un dossier ici ou cliquez sur Choisir"
        case .en: return "Drop a folder here or click Choose"
        case .es: return "Arrastra una carpeta o haz clic en Elegir"
        }
    }
    var destEmptyTitle: String {
        switch language {
        case .fr: return "Aucune destination"
        case .en: return "No destination"
        case .es: return "Ningún destino"
        }
    }
    var destEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez un ou plusieurs dossiers — copie simultanée"
        case .en: return "Drop one or several folders — simultaneous copy"
        case .es: return "Arrastra una o varias carpetas — copia simultánea"
        }
    }
    var destAddTitle: String {
        switch language {
        case .fr: return "Ajouter une destination"
        case .en: return "Add a destination"
        case .es: return "Añadir un destino"
        }
    }
    var destAddSubtitle: String {
        switch language {
        case .fr: return "Glissez un dossier ici"
        case .en: return "Drop a folder here"
        case .es: return "Arrastra una carpeta aquí"
        }
    }

    // MARK: - Buttons / actions
    var buttonChoose: String {
        switch language {
        case .fr: return "Choisir"
        case .en: return "Choose"
        case .es: return "Elegir"
        }
    }
    var buttonAdd: String {
        switch language {
        case .fr: return "Ajouter"
        case .en: return "Add"
        case .es: return "Añadir"
        }
    }
    var buttonClear: String {
        switch language {
        case .fr: return "Effacer"
        case .en: return "Clear"
        case .es: return "Limpiar"
        }
    }
    var buttonExportMHL: String {
        switch language {
        case .fr: return "Exporter MHL…"
        case .en: return "Export MHL…"
        case .es: return "Exportar MHL…"
        }
    }
    var panelSelect: String {
        switch language {
        case .fr: return "Sélectionner"
        case .en: return "Select"
        case .es: return "Seleccionar"
        }
    }
    var panelExportTitle: String {
        switch language {
        case .fr: return "Exporter le rapport MHL"
        case .en: return "Export MHL report"
        case .es: return "Exportar informe MHL"
        }
    }

    // MARK: - Stats
    var statFound: String {
        switch language {
        case .fr: return "Trouvés"
        case .en: return "Found"
        case .es: return "Encontrados"
        }
    }
    var statCopied: String {
        switch language {
        case .fr: return "Copiés"
        case .en: return "Copied"
        case .es: return "Copiados"
        }
    }
    var statVerified: String {
        switch language {
        case .fr: return "Vérifiés"
        case .en: return "Verified"
        case .es: return "Verificados"
        }
    }
    var statFailed: String {
        switch language {
        case .fr: return "Erreurs"
        case .en: return "Errors"
        case .es: return "Errores"
        }
    }

    // MARK: - Action button
    var actionInterrupt: String {
        switch language {
        case .fr: return "Interrompre la copie"
        case .en: return "Interrupt copy"
        case .es: return "Interrumpir la copia"
        }
    }
    var actionInterruptRegistered: String {
        switch language {
        case .fr: return "Interruption enregistrée…"
        case .en: return "Interruption registered…"
        case .es: return "Interrupción registrada…"
        }
    }
    var interruptHint: String {
        switch language {
        case .fr: return "La progression est conservée en cas d'interruption — la copie reprendra où elle s'est arrêtée"
        case .en: return "Progress is preserved if you interrupt — the copy will resume where it stopped"
        case .es: return "El progreso se conserva si interrumpes — la copia continuará donde se detuvo"
        }
    }
    func actionRetryFailed(count: Int) -> String {
        switch language {
        case .fr: return "Recopier les fichiers en erreur (\(count))"
        case .en: return "Re-copy failed files (\(count))"
        case .es: return "Volver a copiar los archivos con error (\(count))"
        }
    }
    var actionStartSim: String {
        switch language {
        case .fr: return "Lancer la simulation"
        case .en: return "Start simulation"
        case .es: return "Iniciar simulación"
        }
    }
    var actionStart: String {
        switch language {
        case .fr: return "Lancer la copie sécurisée"
        case .en: return "Start secure copy"
        case .es: return "Iniciar copia segura"
        }
    }
    var actionStartVerify: String {
        switch language {
        case .fr: return "Lancer la vérification"
        case .en: return "Start verification"
        case .es: return "Iniciar verificación"
        }
    }

    // MARK: - Journal empty
    var journalEmpty: String {
        switch language {
        case .fr: return "Aucune activité pour le moment"
        case .en: return "No activity yet"
        case .es: return "Sin actividad por ahora"
        }
    }

    // MARK: - Footer
    var footerCredit: String {
        switch language {
        case .fr: return "MisiCopy créé par Matthieu Misiraca"
        case .en: return "MisiCopy by Matthieu Misiraca"
        case .es: return "MisiCopy por Matthieu Misiraca"
        }
    }

    // MARK: - Engine logs
    func logSourceSelected(_ name: String) -> String {
        switch language {
        case .fr: return "Source sélectionnée — \(name)"
        case .en: return "Source selected — \(name)"
        case .es: return "Origen seleccionado — \(name)"
        }
    }
    func logDestAdded(_ name: String) -> String {
        switch language {
        case .fr: return "Destination ajoutée — \(name)"
        case .en: return "Destination added — \(name)"
        case .es: return "Destino añadido — \(name)"
        }
    }
    var logCancelRequested: String {
        switch language {
        case .fr: return "Annulation demandée"
        case .en: return "Cancellation requested"
        case .es: return "Cancelación solicitada"
        }
    }
    var logNoSource: String {
        switch language {
        case .fr: return "Aucune source sélectionnée"
        case .en: return "No source selected"
        case .es: return "Ningún origen seleccionado"
        }
    }
    var logNoDestination: String {
        switch language {
        case .fr: return "Aucune destination sélectionnée"
        case .en: return "No destination selected"
        case .es: return "Ningún destino seleccionado"
        }
    }
    var logIndexing: String {
        switch language {
        case .fr: return "Indexation des fichiers…"
        case .en: return "Indexing files…"
        case .es: return "Indexando archivos…"
        }
    }
    var settingsAlgorithmSection: String {
        switch language {
        case .fr: return "Algorithme de checksum"
        case .en: return "Checksum algorithm"
        case .es: return "Algoritmo de checksum"
        }
    }
    var settingsAlgorithmFooter: String {
        switch language {
        case .fr: return "xxHash3 (64-bit) est recommandé : c'est le plus rapide sur Apple Silicon et le standard de l'industrie pour détecter la corruption accidentelle. SHA-256 est un algorithme cryptographique : il ne détecte pas mieux les erreurs de copie mais est 8 à 10 fois plus lent — réservez-le aux livraisons qui l'exigent contractuellement."
        case .en: return "xxHash3 (64-bit) is recommended: the fastest on Apple Silicon and the industry standard for detecting accidental corruption. SHA-256 is a cryptographic algorithm: it detects copy errors no better but runs 8–10× slower — reserve it for deliveries that contractually require it."
        case .es: return "xxHash3 (64-bit) es el recomendado: el más rápido en Apple Silicon y el estándar de la industria para detectar corrupción accidental. SHA-256 es un algoritmo criptográfico: no detecta mejor los errores de copia pero es 8–10 veces más lento — resérvalo para entregas que lo exijan contractualmente."
        }
    }
    func logCascadeEnabled(_ name: String) -> String {
        switch language {
        case .fr: return "« \(name) » passe en cascade — alimentée depuis la première destination après la copie principale"
        case .en: return "\"\(name)\" switched to cascade — fed from the first destination after the primary copy"
        case .es: return "« \(name) » pasa a cascada — alimentada desde el primer destino tras la copia principal"
        }
    }
    func logCascadeDisabled(_ name: String) -> String {
        switch language {
        case .fr: return "« \(name) » repasse en destination directe"
        case .en: return "\"\(name)\" switched back to a direct destination"
        case .es: return "« \(name) » vuelve a destino directo"
        }
    }
    var logSourcesFreed: String {
        switch language {
        case .fr: return "✅ Copie principale vérifiée — les cartes sources sont libérées, la cascade prend le relais"
        case .en: return "✅ Primary copy verified — source cards are released, the cascade takes over"
        case .es: return "✅ Copia principal verificada — las tarjetas origen quedan libres, la cascada toma el relevo"
        }
    }
    func logCascadeStart(feed: String, count: Int) -> String {
        switch language {
        case .fr: return "Cascade : alimentation de \(count) destination(s) depuis « \(feed) »…"
        case .en: return "Cascade: feeding \(count) destination(s) from \"\(feed)\"…"
        case .es: return "Cascada: alimentando \(count) destino(s) desde « \(feed) »…"
        }
    }
    func logCascadeDone(count: Int) -> String {
        switch language {
        case .fr: return "Cascade terminée — \(count) destination(s) alimentée(s)"
        case .en: return "Cascade finished — \(count) destination(s) fed"
        case .es: return "Cascada terminada — \(count) destino(s) alimentado(s)"
        }
    }
    func logCascadeFeedMismatch(_ name: String) -> String {
        switch language {
        case .fr: return "cascade : le fichier relu sur « \(name) » ne correspond plus à la source"
        case .en: return "cascade: the file re-read from \"\(name)\" no longer matches the source"
        case .es: return "cascada: el archivo releído de « \(name) » ya no coincide con el origen"
        }
    }
    var logCascadeAllFallback: String {
        switch language {
        case .fr: return "Toutes les destinations sont en cascade — il faut au moins une destination directe pour les alimenter. Les drapeaux cascade sont ignorés pour cette copie."
        case .en: return "All destinations are set to cascade — at least one direct destination is needed to feed them. Cascade flags are ignored for this copy."
        case .es: return "Todos los destinos están en cascada — se necesita al menos un destino directo para alimentarlos. Las marcas de cascada se ignoran en esta copia."
        }
    }
    /// Locale-aware short date+time ("19/07/2026 21:45") for banners.
    func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        switch language {
        case .fr: formatter.locale = Locale(identifier: "fr_FR")
        case .en: formatter.locale = Locale(identifier: "en_US")
        case .es: formatter.locale = Locale(identifier: "es_ES")
        }
        return formatter.string(from: date)
    }
    var remotePhaseCascade: String {
        switch language {
        case .fr: return "Cascade — cartes libérées ✅"
        case .en: return "Cascade — cards released ✅"
        case .es: return "Cascada — tarjetas liberadas ✅"
        }
    }
    func logKnownCardDetected(_ name: String, when: String) -> String {
        switch language {
        case .fr: return "Carte « \(name) » reconnue — déjà déchargée le \(when)"
        case .en: return "Card \"\(name)\" recognized — already offloaded on \(when)"
        case .es: return "Tarjeta « \(name) » reconocida — ya descargada el \(when)"
        }
    }
    func cardAlreadyOffloaded(_ name: String, when: String, files: Int, volume: String) -> String {
        switch language {
        case .fr: return "« \(name) » déjà déchargée le \(when) — \(files) fichier(s), \(volume)"
        case .en: return "\"\(name)\" already offloaded on \(when) — \(files) file(s), \(volume)"
        case .es: return "« \(name) » ya descargada el \(when) — \(files) archivo(s), \(volume)"
        }
    }
    var buttonReverify: String {
        switch language {
        case .fr: return "Re-vérifier"
        case .en: return "Re-verify"
        case .es: return "Re-verificar"
        }
    }
    var buttonRecopy: String {
        switch language {
        case .fr: return "Recopier"
        case .en: return "Re-copy"
        case .es: return "Recopiar"
        }
    }
    func logPreflightSpace(_ name: String, missing: String) -> String {
        switch language {
        case .fr: return "⛔️ Copie refusée : espace insuffisant sur « \(name) » — il manque \(missing)"
        case .en: return "⛔️ Copy refused: not enough space on \"\(name)\" — \(missing) missing"
        case .es: return "⛔️ Copia rechazada: espacio insuficiente en « \(name) » — faltan \(missing)"
        }
    }
    var preflightAlertTitle: String {
        switch language {
        case .fr: return "Espace insuffisant"
        case .en: return "Not enough space"
        case .es: return "Espacio insuficiente"
        }
    }
    func preflightAlertMessage(name: String, needed: String, free: String, missing: String) -> String {
        switch language {
        case .fr: return "La copie nécessite \(needed) mais « \(name) » n'a que \(free) de libre (il manque \(missing)).\n\nLibérez de l'espace ou choisissez une autre destination — rien n'a été copié."
        case .en: return "The copy needs \(needed) but \"\(name)\" only has \(free) free (\(missing) missing).\n\nFree up space or pick another destination — nothing was copied."
        case .es: return "La copia necesita \(needed) pero « \(name) » solo tiene \(free) libres (faltan \(missing)).\n\nLibera espacio o elige otro destino — no se copió nada."
        }
    }
    func todaySummary(cards: Int, volume: String, errors: Int) -> String {
        switch language {
        case .fr:
            let err = errors == 0 ? "0 erreur" : "\(errors) erreur(s)"
            return "Aujourd'hui : \(cards) carte(s) · \(volume) · \(err)"
        case .en:
            let err = errors == 0 ? "0 errors" : "\(errors) error(s)"
            return "Today: \(cards) card(s) · \(volume) · \(err)"
        case .es:
            let err = errors == 0 ? "0 errores" : "\(errors) error(es)"
            return "Hoy: \(cards) tarjeta(s) · \(volume) · \(err)"
        }
    }
    func logDestSpeedMeasured(_ name: String, mbs: Double) -> String {
        let v = Int(mbs.rounded())
        switch language {
        case .fr: return "Vitesse mesurée sur « \(name) » : écriture ≈ \(v) Mo/s"
        case .en: return "Measured speed on \"\(name)\": write ≈ \(v) MB/s"
        case .es: return "Velocidad medida en « \(name) »: escritura ≈ \(v) MB/s"
        }
    }
    var unitMBs: String {
        switch language {
        case .fr: return "Mo/s"
        case .en: return "MB/s"
        case .es: return "MB/s"
        }
    }
    var tooltipFastestDrive: String {
        switch language {
        case .fr: return "Le disque le plus rapide — idéal en destination directe"
        case .en: return "The fastest drive — ideal as a direct destination"
        case .es: return "El disco más rápido — ideal como destino directo"
        }
    }
    var tooltipSpeedBadge: String {
        switch language {
        case .fr: return "Vitesse d'écriture mesurée — cliquez pour re-mesurer"
        case .en: return "Measured write speed — click to re-measure"
        case .es: return "Velocidad de escritura medida — haz clic para volver a medir"
        }
    }
    var tooltipSlowDrive: String {
        switch language {
        case .fr: return "Disque le plus lent — bon candidat pour la cascade (bouton ↳)"
        case .en: return "Slowest drive — a good cascade candidate (↳ button)"
        case .es: return "Disco más lento — buen candidato para la cascada (botón ↳)"
        }
    }
    func completionDialogMessage(verifyOnly: Bool, verified: Int, failed: Int,
                                 bytes: String, duration: String) -> String {
        let action: String
        switch language {
        case .fr: action = verifyOnly ? "vérifiés" : "copiés et vérifiés"
        case .en: action = verifyOnly ? "verified" : "copied and verified"
        case .es: action = verifyOnly ? "verificados" : "copiados y verificados"
        }
        switch language {
        case .fr:
            return failed == 0
                ? "\(verified) fichier(s) \(action) — \(bytes) en \(duration)."
                : "\(verified) fichier(s) vérifiés, \(failed) en erreur — \(bytes) en \(duration).\nUtilisez « Recopier les fichiers en erreur » pour retenter."
        case .en:
            return failed == 0
                ? "\(verified) file(s) \(action) — \(bytes) in \(duration)."
                : "\(verified) file(s) verified, \(failed) failed — \(bytes) in \(duration).\nUse \"Re-copy failed files\" to retry."
        case .es:
            return failed == 0
                ? "\(verified) archivo(s) \(action) — \(bytes) en \(duration)."
                : "\(verified) archivo(s) verificados, \(failed) con error — \(bytes) en \(duration).\nUsa « Volver a copiar los archivos con error » para reintentar."
        }
    }
    var settingsCompletionDialogToggle: String {
        switch language {
        case .fr: return "Boîte de dialogue en fin de copie"
        case .en: return "Dialog box when a copy finishes"
        case .es: return "Cuadro de diálogo al terminar la copia"
        }
    }
    var cascadeAlertTitle: String {
        switch language {
        case .fr: return "Impossible de tout passer en cascade"
        case .en: return "Can't set everything to cascade"
        case .es: return "No se puede poner todo en cascada"
        }
    }
    var cascadeAlertMessage: String {
        switch language {
        case .fr: return "Une cascade est alimentée depuis la première destination directe. Il faut donc conserver au moins une destination directe (idéalement le disque le plus rapide ⚡) — les cascades seront copiées depuis elle une fois la copie principale vérifiée."
        case .en: return "A cascade is fed from the first direct destination. Keep at least one direct destination (ideally the fastest drive ⚡) — the cascades will be copied from it once the primary copy is verified."
        case .es: return "Una cascada se alimenta desde el primer destino directo. Conserva al menos un destino directo (idealmente el disco más rápido ⚡) — las cascadas se copiarán desde él una vez verificada la copia principal."
        }
    }
    var tooltipCascade: String {
        switch language {
        case .fr: return "Cascade : cette destination sera alimentée depuis la première destination une fois la copie principale vérifiée — la carte est libérée plus tôt"
        case .en: return "Cascade: this destination is fed from the first destination once the primary copy is verified — the card is released earlier"
        case .es: return "Cascada: este destino se alimenta desde el primer destino una vez verificada la copia principal — la tarjeta queda libre antes"
        }
    }
    var logVerifyNoReportWritten: String {
        switch language {
        case .fr: return "Vérification seule : aucun fichier écrit sur les destinations — exportez le rapport via Fichier → Exporter si besoin"
        case .en: return "Verify only: nothing written to the destinations — export the report via File → Export if needed"
        case .es: return "Solo verificación: no se escribe nada en los destinos — exporta el informe vía Archivo → Exportar si lo necesitas"
        }
    }
    var logWatchAutoStartSkippedVerify: String {
        switch language {
        case .fr: return "Auto-start ignoré : le mode « Vérification seule » est actif — passez en mode copie pour décharger cette carte"
        case .en: return "Auto-start skipped: 'Verify only' mode is active — switch to a copy mode to offload this card"
        case .es: return "Auto-inicio omitido: el modo « Solo verificación » está activo — cambia a un modo de copia para descargar esta tarjeta"
        }
    }
    func logResumeSkipped(count: Int) -> String {
        switch language {
        case .fr: return "⏩ \(count) fichier(s) déjà sécurisé(s) — ignorés (reprise)"
        case .en: return "⏩ \(count) file(s) already secured — skipped (resume)"
        case .es: return "⏩ \(count) archivo(s) ya asegurado(s) — omitidos (reanudación)"
        }
    }
    func logResumeSaved(count: Int) -> String {
        switch language {
        case .fr: return "Progression sauvegardée (\(count) fichier(s)) — la prochaine copie reprendra où elle s'est arrêtée"
        case .en: return "Progress saved (\(count) file(s)) — the next copy will resume where it stopped"
        case .es: return "Progreso guardado (\(count) archivo(s)) — la próxima copia continuará donde se detuvo"
        }
    }
    func logParallelSources(count: Int) -> String {
        switch language {
        case .fr: return "Copie parallèle : \(count) sources traitées simultanément"
        case .en: return "Parallel copy: \(count) sources processed simultaneously"
        case .es: return "Copia paralela: \(count) orígenes procesados simultáneamente"
        }
    }
    func logRetryFailedStart(count: Int) -> String {
        switch language {
        case .fr: return "Relance des \(count) fichier(s) en erreur uniquement…"
        case .en: return "Re-running on the \(count) failed file(s) only…"
        case .es: return "Reintentando solo los \(count) archivo(s) con error…"
        }
    }
    func logRetryFailedIndexing(count: Int) -> String {
        switch language {
        case .fr: return "\(count) fichier(s) à reprendre — copie ciblée"
        case .en: return "\(count) file(s) to retry — targeted copy"
        case .es: return "\(count) archivo(s) a reintentar — copia dirigida"
        }
    }
    var errMissingSourceChecksum: String {
        switch language {
        case .fr: return "empreinte source manquante"
        case .en: return "missing source checksum"
        case .es: return "falta la suma de comprobación origen"
        }
    }
    var pdfPreviewUnavailable: String {
        switch language {
        case .fr: return "Aperçu indisponible"
        case .en: return "Preview unavailable"
        case .es: return "Vista previa no disponible"
        }
    }
    func logFilesFound(count: Int, bytes: String) -> String {
        switch language {
        case .fr: return "\(count) fichier(s) trouvé(s) — \(bytes)"
        case .en: return "\(count) file(s) found — \(bytes)"
        case .es: return "\(count) archivo(s) encontrado(s) — \(bytes)"
        }
    }
    var logSimulation: String {
        switch language {
        case .fr: return "Mode simulation — aucun fichier ne sera copié"
        case .en: return "Simulation mode — no file will be copied"
        case .es: return "Modo simulación — no se copiará ningún archivo"
        }
    }
    var logCancelled: String {
        switch language {
        case .fr: return "Opération annulée"
        case .en: return "Operation cancelled"
        case .es: return "Operación cancelada"
        }
    }
    func logDone(verified: Int, found: Int) -> String {
        switch language {
        case .fr: return "Terminé — \(verified)/\(found) vérifié(s)"
        case .en: return "Done — \(verified)/\(found) verified"
        case .es: return "Listo — \(verified)/\(found) verificados"
        }
    }
    func logDoneWithErrors(_ failed: Int) -> String {
        switch language {
        case .fr: return "Terminé avec \(failed) erreur(s)"
        case .en: return "Done with \(failed) error(s)"
        case .es: return "Terminado con \(failed) error(es)"
        }
    }
    var flashSuccessTitle: String {
        switch language {
        case .fr: return "Copie réussie"
        case .en: return "Copy succeeded"
        case .es: return "Copia exitosa"
        }
    }
    func flashSuccessSubtitle(verified: Int, bytes: String) -> String {
        switch language {
        case .fr: return "\(verified) fichier(s) vérifié(s) — \(bytes)"
        case .en: return "\(verified) file(s) verified — \(bytes)"
        case .es: return "\(verified) archivo(s) verificado(s) — \(bytes)"
        }
    }
    var flashFailureTitle: String {
        switch language {
        case .fr: return "Copie terminée avec erreurs"
        case .en: return "Copy finished with errors"
        case .es: return "Copia terminada con errores"
        }
    }
    func flashFailureSubtitle(failed: Int) -> String {
        switch language {
        case .fr: return "\(failed) fichier(s) en erreur — voir le journal"
        case .en: return "\(failed) file(s) failed — check the activity log"
        case .es: return "\(failed) archivo(s) con error — revisa el registro"
        }
    }
    var flashCancelledTitle: String {
        switch language {
        case .fr: return "Copie annulée"
        case .en: return "Copy cancelled"
        case .es: return "Copia cancelada"
        }
    }
    var flashCancelledSubtitle: String {
        switch language {
        case .fr: return "Aucun REEL n'a été engagé"
        case .en: return "No REEL has been committed"
        case .es: return "No se ha registrado ningún REEL"
        }
    }
    func logFileOK(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — OK"
        case .en: return "\(name) — OK"
        case .es: return "\(name) — OK"
        }
    }
    func logDoubleVerifyPass(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — source re-vérifiée (stable)"
        case .en: return "\(name) — source re-verified (stable)"
        case .es: return "\(name) — origen re-verificado (estable)"
        }
    }
    func logSourceReadError(_ message: String) -> String {
        switch language {
        case .fr: return "lecture source — \(message)"
        case .en: return "source read — \(message)"
        case .es: return "lectura origen — \(message)"
        }
    }
    func logCopyError(destination: String, message: String) -> String {
        switch language {
        case .fr: return "copie vers \(destination) — \(message)"
        case .en: return "copy to \(destination) — \(message)"
        case .es: return "copia hacia \(destination) — \(message)"
        }
    }
    func logChecksumMismatch(_ destination: String) -> String {
        switch language {
        case .fr: return "checksum différent (\(destination))"
        case .en: return "checksum mismatch (\(destination))"
        case .es: return "checksum distinto (\(destination))"
        }
    }
    var logSourceUnstable: String {
        switch language {
        case .fr: return "source instable"
        case .en: return "unstable source"
        case .es: return "origen inestable"
        }
    }
    func logVerifyError(_ message: String) -> String {
        switch language {
        case .fr: return "vérif destination — \(message)"
        case .en: return "destination verification — \(message)"
        case .es: return "verificación destino — \(message)"
        }
    }
    var exportUnavailable: String {
        switch language {
        case .fr: return "Export indisponible pendant la copie"
        case .en: return "Export unavailable during copy"
        case .es: return "Exportación no disponible durante la copia"
        }
    }
    var exportEncodeFailed: String {
        switch language {
        case .fr: return "Encodage du rapport impossible"
        case .en: return "Cannot encode report"
        case .es: return "No se puede codificar el informe"
        }
    }
    func exportFailed(_ message: String) -> String {
        switch language {
        case .fr: return "Export échoué — \(message)"
        case .en: return "Export failed — \(message)"
        case .es: return "Exportación fallida — \(message)"
        }
    }
    func exportSucceeded(_ name: String) -> String {
        switch language {
        case .fr: return "Rapport MHL exporté — \(name)"
        case .en: return "MHL report exported — \(name)"
        case .es: return "Informe MHL exportado — \(name)"
        }
    }
    func pdfReportWritten(_ name: String, in folder: String) -> String {
        switch language {
        case .fr: return "Rapport PDF écrit dans \(folder) — \(name)"
        case .en: return "PDF report written to \(folder) — \(name)"
        case .es: return "Informe PDF escrito en \(folder) — \(name)"
        }
    }
    func pdfReportFailed(_ folder: String) -> String {
        switch language {
        case .fr: return "Écriture du rapport PDF impossible dans \(folder)"
        case .en: return "Could not write PDF report to \(folder)"
        case .es: return "No se pudo escribir el informe PDF en \(folder)"
        }
    }
    func logEjected(_ name: String) -> String {
        switch language {
        case .fr: return "Volume éjecté — \(name)"
        case .en: return "Volume ejected — \(name)"
        case .es: return "Volumen expulsado — \(name)"
        }
    }
    func logEjectAttempt(_ name: String) -> String {
        switch language {
        case .fr: return "Tentative d'éjection — \(name)"
        case .en: return "Eject attempt — \(name)"
        case .es: return "Intento de expulsión — \(name)"
        }
    }
    // MARK: - Menu bar (localized)

    var menuFile: String {
        switch language {
        case .fr: return "Fichier"
        case .en: return "File"
        case .es: return "Archivo"
        }
    }
    var menuJob: String {
        switch language {
        case .fr: return "Tâche"
        case .en: return "Job"
        case .es: return "Tarea"
        }
    }
    var menuOptions: String {
        switch language {
        case .fr: return "Options"
        case .en: return "Options"
        case .es: return "Opciones"
        }
    }
    var menuPresetsTitle: String {
        switch language {
        case .fr: return "Profils"
        case .en: return "Presets"
        case .es: return "Perfiles"
        }
    }
    var menuLanguageTitle: String {
        switch language {
        case .fr: return "Langue"
        case .en: return "Language"
        case .es: return "Idioma"
        }
    }
    var menuCheckForUpdates: String {
        switch language {
        case .fr: return "Vérifier les mises à jour…"
        case .en: return "Check for Updates…"
        case .es: return "Buscar actualizaciones…"
        }
    }
    /// Title of the system-injected Settings menu item. SwiftUI's
    /// `Settings { ... }` scene reads it from the system localisation, so
    /// we override it via AppKit to follow the in-app language.
    var menuSettings: String {
        switch language {
        case .fr: return "Réglages…"
        case .en: return "Settings…"
        case .es: return "Ajustes…"
        }
    }
    var menuDonate: String {
        switch language {
        case .fr: return "Acheter MisiCopy…"
        case .en: return "Buy MisiCopy…"
        case .es: return "Comprar MisiCopy…"
        }
    }
    var donateButton: String {
        switch language {
        case .fr: return "Acheter MisiCopy"
        case .en: return "Buy MisiCopy"
        case .es: return "Comprar MisiCopy"
        }
    }
    var donateBadge: String {
        switch language {
        case .fr: return "DONATEUR"
        case .en: return "DONOR"
        case .es: return "DONANTE"
        }
    }
    var donateQuitTitle: String {
        switch language {
        case .fr: return "Essai expiré"
        case .en: return "Trial expired"
        case .es: return "Prueba expirada"
        }
    }
    var donateQuitBody: String {
        switch language {
        case .fr:
            return "Votre essai de \(LicenseConfig.trialDays) jours est terminé. Achetez MisiCopy pour continuer à l'utiliser sans limite — un seul achat, mises à jour incluses."
        case .en:
            return "Your \(LicenseConfig.trialDays)-day trial has ended. Purchase MisiCopy to keep using it without limits — one purchase, updates included."
        case .es:
            return "Tu prueba de \(LicenseConfig.trialDays) días ha finalizado. Compra MisiCopy para seguir usándolo sin límites — una sola compra, actualizaciones incluidas."
        }
    }
    var donateQuitContinue: String {
        switch language {
        case .fr: return "Plus tard"
        case .en: return "Later"
        case .es: return "Más tarde"
        }
    }
    var licenseStateFree: String {
        switch language {
        case .fr: return "Version gratuite"
        case .en: return "Free version"
        case .es: return "Versión gratuita"
        }
    }
    var licenseStateFreeHint: String {
        switch language {
        case .fr: return "Saisissez votre clé reçue après un don pour masquer le rappel à la fermeture"
        case .en: return "Enter the key you received after donating to hide the quit reminder"
        case .es: return "Introduce tu clave recibida tras donar para ocultar el recordatorio al salir"
        }
    }
    var emailFieldLabel: String {
        switch language {
        case .fr: return "Email (optionnel)"
        case .en: return "Email (optional)"
        case .es: return "Email (opcional)"
        }
    }
    var emailFieldHint: String {
        switch language {
        case .fr: return "Pour affichage uniquement"
        case .en: return "Display only"
        case .es: return "Solo para visualización"
        }
    }
    var bugReportButton: String {
        switch language {
        case .fr: return "BUG ?"
        case .en: return "BUG?"
        case .es: return "¿BUG?"
        }
    }
    var bugReportTooltip: String {
        switch language {
        case .fr: return "Signaler un bug par email à misicopy@misiraca.com"
        case .en: return "Report a bug by email to misicopy@misiraca.com"
        case .es: return "Reportar un bug por email a misicopy@misiraca.com"
        }
    }

    // MARK: - Remote sync (iPhone)
    var remoteSectionLocal: String {
        switch language {
        case .fr: return "Réseau local (Wi-Fi)"
        case .en: return "Local network (Wi-Fi)"
        case .es: return "Red local (Wi-Fi)"
        }
    }
    var remoteToggleEnable: String {
        switch language {
        case .fr: return "Activer le suivi depuis un iPhone"
        case .en: return "Allow iPhone live monitoring"
        case .es: return "Activar seguimiento desde iPhone"
        }
    }
    var remoteToggleFooter: String {
        switch language {
        case .fr: return "Permet à votre iPhone (sur le même Wi-Fi) de suivre la progression de la copie en temps réel et de la mettre en pause à distance. Aucune donnée ne quitte votre réseau."
        case .en: return "Lets your iPhone (on the same Wi-Fi) monitor copy progress live and pause it remotely. No data ever leaves your network."
        case .es: return "Permite a tu iPhone (en la misma red Wi-Fi) seguir el progreso de la copia en directo y pausarla remotamente. Ningún dato sale de tu red."
        }
    }
    var remoteSectionStatus: String {
        switch language {
        case .fr: return "État"
        case .en: return "Status"
        case .es: return "Estado"
        }
    }
    var remoteStatusListening: String {
        switch language {
        case .fr: return "Service en écoute"
        case .en: return "Service listening"
        case .es: return "Servicio escuchando"
        }
    }
    var remoteStatusStarting: String {
        switch language {
        case .fr: return "Démarrage…"
        case .en: return "Starting…"
        case .es: return "Iniciando…"
        }
    }
    var remotePortLabel: String {
        switch language {
        case .fr: return "Port TCP"
        case .en: return "TCP port"
        case .es: return "Puerto TCP"
        }
    }
    var remoteClientsLabel: String {
        switch language {
        case .fr: return "iPhone connectés"
        case .en: return "Connected iPhones"
        case .es: return "iPhone conectados"
        }
    }
    var remoteSectionSecret: String {
        switch language {
        case .fr: return "Clé d'appairage"
        case .en: return "Pairing key"
        case .es: return "Clave de emparejamiento"
        }
    }
    var remoteSecretLabel: String {
        switch language {
        case .fr: return "Secret partagé"
        case .en: return "Shared secret"
        case .es: return "Secreto compartido"
        }
    }
    var remoteSecretFooter: String {
        switch language {
        case .fr: return "Ce secret sera codé dans le QR code d'appairage de l'app iPhone (à venir). Régénérez-le si vous suspectez qu'il a été compromis — tous les iPhones devront alors être ré-appairés."
        case .en: return "This secret will be embedded in the iPhone app pairing QR code (coming soon). Regenerate it if you think it was leaked — every paired iPhone will then need to pair again."
        case .es: return "Este secreto se incrustará en el código QR de emparejamiento de la app iPhone (próximamente). Regenéralo si crees que se filtró — todos los iPhone tendrán que volver a emparejarse."
        }
    }
    var remoteRegenerateSecret: String {
        switch language {
        case .fr: return "Régénérer le secret"
        case .en: return "Regenerate secret"
        case .es: return "Regenerar secreto"
        }
    }
    var remoteSectionPairing: String {
        switch language {
        case .fr: return "Code d'appairage"
        case .en: return "Pairing code"
        case .es: return "Código de emparejamiento"
        }
    }
    var remotePairingFooter: String {
        switch language {
        case .fr: return "Scannez ce QR code depuis l'app iPhone MisiCopy Remote (à venir) pour autoriser votre téléphone à suivre les copies de ce Mac."
        case .en: return "Scan this QR code from the iPhone MisiCopy Remote app (coming soon) to authorize your phone to monitor copies from this Mac."
        case .es: return "Escanea este código QR desde la app iPhone MisiCopy Remote (próximamente) para autorizar a tu teléfono a seguir las copias de este Mac."
        }
    }
    var remotePairingError: String {
        switch language {
        case .fr: return "Impossible de générer le QR code."
        case .en: return "Could not generate the QR code."
        case .es: return "No se pudo generar el código QR."
        }
    }
    var remoteCopyPayload: String {
        switch language {
        case .fr: return "Copier le payload"
        case .en: return "Copy payload"
        case .es: return "Copiar payload"
        }
    }

    // MARK: - Settings tabs
    var settingsTabGeneral: String {
        switch language {
        case .fr: return "Général"
        case .en: return "General"
        case .es: return "General"
        }
    }
    var settingsTabRenaming: String {
        switch language {
        case .fr: return "Renommage"
        case .en: return "Renaming"
        case .es: return "Renombrado"
        }
    }
    var settingsTabFilters: String {
        switch language {
        case .fr: return "Filtres"
        case .en: return "Filters"
        case .es: return "Filtros"
        }
    }
    var settingsTabWatch: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        }
    }
    var settingsTabIntegrations: String {
        switch language {
        case .fr: return "Intégrations"
        case .en: return "Integrations"
        case .es: return "Integraciones"
        }
    }
    var settingsTabRemote: String {
        switch language {
        case .fr: return "iPhone"
        case .en: return "iPhone"
        case .es: return "iPhone"
        }
    }
    var settingsTabAdvanced: String {
        switch language {
        case .fr: return "Avancé"
        case .en: return "Advanced"
        case .es: return "Avanzado"
        }
    }

    // MARK: - Settings: General tab
    var settingsGeneralSection: String {
        switch language {
        case .fr: return "Interface"
        case .en: return "Interface"
        case .es: return "Interfaz"
        }
    }
    var settingsGeneralStatusItem: String {
        switch language {
        case .fr: return "Icône dans la barre des menus"
        case .en: return "Show icon in menu bar"
        case .es: return "Ícono en la barra de menús"
        }
    }

    // MARK: - Settings: Watch tab
    var settingsWatchSectionTitle: String {
        switch language {
        case .fr: return "Mode surveillance"
        case .en: return "Watch mode"
        case .es: return "Modo vigilancia"
        }
    }
    var settingsWatchAutoAdd: String {
        switch language {
        case .fr: return "Ajout automatique des cartes / disques externes"
        case .en: return "Auto-add inserted cards / external drives"
        case .es: return "Añadir automáticamente las tarjetas / discos externos"
        }
    }
    var settingsWatchAutoStart: String {
        switch language {
        case .fr: return "Lancement automatique de la copie"
        case .en: return "Auto-start the copy"
        case .es: return "Iniciar la copia automáticamente"
        }
    }
    var settingsWatchFooter: String {
        switch language {
        case .fr: return "Quand activé, toute carte ou disque externe inséré est ajouté en source. Si le lancement automatique est aussi activé et que des destinations sont configurées, la copie démarre immédiatement."
        case .en: return "When enabled, any inserted card or external drive is added as a source. If auto-start is also on and destinations are configured, the copy begins immediately."
        case .es: return "Si está activado, cualquier tarjeta o disco externo insertado se añade como fuente. Con el inicio automático activado y destinos configurados, la copia empieza al instante."
        }
    }

    // MARK: - Settings: Integrations tab
    var settingsIntegrationsSlackHeader: String {
        switch language {
        case .fr: return "Notification Slack"
        case .en: return "Slack notification"
        case .es: return "Notificación Slack"
        }
    }
    var settingsIntegrationsSlackPlaceholder: String {
        switch language {
        case .fr: return "URL Slack"
        case .en: return "Slack URL"
        case .es: return "URL de Slack"
        }
    }
    var settingsIntegrationsSlackFooter: String {
        switch language {
        case .fr: return "Crée un Incoming Webhook dans Slack → colle l'URL ci-dessus. Un message est envoyé à la fin de chaque copie."
        case .en: return "Create an Incoming Webhook in Slack → paste the URL above. A message is posted at the end of every copy."
        case .es: return "Crea un Incoming Webhook en Slack → pega la URL arriba. Se envía un mensaje al final de cada copia."
        }
    }
    var settingsIntegrationsWebhookHeader: String {
        switch language {
        case .fr: return "Webhook générique (Email / Zapier / Make)"
        case .en: return "Generic webhook (Email / Zapier / Make)"
        case .es: return "Webhook genérico (Email / Zapier / Make)"
        }
    }
    var settingsIntegrationsWebhookPlaceholder: String {
        switch language {
        case .fr: return "URL générique"
        case .en: return "Generic URL"
        case .es: return "URL genérica"
        }
    }
    var settingsIntegrationsWebhookExample: String {
        switch language {
        case .fr: return "https://hooks.zapier.com/… ou Make.com"
        case .en: return "https://hooks.zapier.com/… or Make.com"
        case .es: return "https://hooks.zapier.com/… o Make.com"
        }
    }
    var settingsIntegrationsWebhookFooter: String {
        switch language {
        case .fr: return "Reçoit un JSON détaillé avec les stats. Compatible avec n'importe quel automate qui accepte un POST JSON."
        case .en: return "Receives a detailed JSON with stats. Compatible with any automation tool that accepts a JSON POST."
        case .es: return "Recibe un JSON detallado con las estadísticas. Compatible con cualquier automatización que acepte un POST JSON."
        }
    }

    // MARK: - Settings: Advanced tab
    var settingsAdvancedFinderSection: String {
        switch language {
        case .fr: return "Métadonnées Finder"
        case .en: return "Finder metadata"
        case .es: return "Metadatos del Finder"
        }
    }
    var settingsAdvancedFinderToggle: String {
        switch language {
        case .fr: return "Préserver les tags couleur Finder"
        case .en: return "Preserve Finder color tags"
        case .es: return "Conservar las etiquetas de color del Finder"
        }
    }
    var settingsAdvancedSymlinksSection: String {
        switch language {
        case .fr: return "Liens symboliques"
        case .en: return "Symbolic links"
        case .es: return "Enlaces simbólicos"
        }
    }
    var settingsAdvancedSymlinksToggle: String {
        switch language {
        case .fr: return "Suivre les symlinks (au lieu de les ignorer)"
        case .en: return "Follow symlinks (instead of skipping them)"
        case .es: return "Seguir los symlinks (en lugar de ignorarlos)"
        }
    }

    // MARK: - Settings: Filters tab
    var settingsFiltersIncludeHeader: String {
        switch language {
        case .fr: return "Extensions à inclure (whitelist)"
        case .en: return "Extensions to include (allowlist)"
        case .es: return "Extensiones a incluir (allowlist)"
        }
    }
    var settingsFiltersIncludePlaceholder: String {
        switch language {
        case .fr: return "À inclure"
        case .en: return "Include"
        case .es: return "Incluir"
        }
    }
    var settingsFiltersIncludeFooter: String {
        switch language {
        case .fr: return "Si renseigné, **seules** ces extensions seront copiées. Laisser vide pour tout copier."
        case .en: return "If set, **only** these extensions will be copied. Leave blank to copy everything."
        case .es: return "Si se rellena, **solo** estas extensiones se copiarán. Dejar vacío para copiar todo."
        }
    }
    var settingsFiltersExcludeHeader: String {
        switch language {
        case .fr: return "Extensions à exclure (blacklist)"
        case .en: return "Extensions to exclude (blocklist)"
        case .es: return "Extensiones a excluir (blocklist)"
        }
    }
    var settingsFiltersExcludePlaceholder: String {
        switch language {
        case .fr: return "À exclure"
        case .en: return "Exclude"
        case .es: return "Excluir"
        }
    }
    var settingsFiltersExcludeFooter: String {
        switch language {
        case .fr: return "Ces extensions seront **ignorées** même si elles passent le filtre d'inclusion. Utile pour les fichiers parasites caméra."
        case .en: return "These extensions are **skipped** even if they pass the include filter. Useful for sidecar camera files."
        case .es: return "Estas extensiones se **omiten** incluso si pasan el filtro de inclusión. Útil para archivos auxiliares de cámara."
        }
    }
    var settingsFiltersSeparatorHint: String {
        switch language {
        case .fr: return "Séparateurs acceptés : virgule, espace, point-virgule. Le point initial est optionnel — `.mxf` ou `mxf` fonctionne pareil."
        case .en: return "Accepted separators: comma, space, semicolon. The leading dot is optional — `.mxf` or `mxf` both work."
        case .es: return "Separadores aceptados: coma, espacio, punto y coma. El punto inicial es opcional — `.mxf` o `mxf` funcionan igual."
        }
    }

    // MARK: - Settings: Renaming tab
    var settingsRenamingSection: String {
        switch language {
        case .fr: return "Renommage dynamique"
        case .en: return "Dynamic renaming"
        case .es: return "Renombrado dinámico"
        }
    }
    var settingsRenamingTemplate: String {
        switch language {
        case .fr: return "Modèle"
        case .en: return "Template"
        case .es: return "Plantilla"
        }
    }
    var settingsRenamingPreview: String {
        switch language {
        case .fr: return "Aperçu"
        case .en: return "Preview"
        case .es: return "Vista previa"
        }
    }
    var settingsRenamingClear: String {
        switch language {
        case .fr: return "Effacer le modèle"
        case .en: return "Clear template"
        case .es: return "Borrar plantilla"
        }
    }
    var settingsRenamingTokensSection: String {
        switch language {
        case .fr: return "Tokens disponibles"
        case .en: return "Available tokens"
        case .es: return "Tokens disponibles"
        }
    }
    var settingsRenamingTokenFilename: String {
        switch language {
        case .fr: return "Nom d'origine sans extension"
        case .en: return "Original name without extension"
        case .es: return "Nombre original sin extensión"
        }
    }
    var settingsRenamingTokenExt: String {
        switch language {
        case .fr: return "Extension d'origine"
        case .en: return "Original extension"
        case .es: return "Extensión original"
        }
    }
    var settingsRenamingTokenSource: String {
        switch language {
        case .fr: return "Nom du dossier source"
        case .en: return "Source folder name"
        case .es: return "Nombre de la carpeta origen"
        }
    }
    var settingsRenamingTokenCamera: String {
        switch language {
        case .fr: return "Caméra détectée (RED, BRAW, ARRI…)"
        case .en: return "Detected camera (RED, BRAW, ARRI…)"
        case .es: return "Cámara detectada (RED, BRAW, ARRI…)"
        }
    }
    var settingsRenamingTokenDate: String {
        switch language {
        case .fr: return "Date — 2026-06-04"
        case .en: return "Date — 2026-06-04"
        case .es: return "Fecha — 2026-06-04"
        }
    }
    var settingsRenamingTokenTime: String {
        switch language {
        case .fr: return "Heure — 14-32-05"
        case .en: return "Time — 14-32-05"
        case .es: return "Hora — 14-32-05"
        }
    }
    var settingsRenamingTokenCounter: String {
        switch language {
        case .fr: return "Compteur incrémenté"
        case .en: return "Incremented counter"
        case .es: return "Contador incrementado"
        }
    }
    var settingsRenamingTokenCounterPadded: String {
        switch language {
        case .fr: return "Compteur avec padding (0001…)"
        case .en: return "Padded counter (0001…)"
        case .es: return "Contador con relleno (0001…)"
        }
    }

    // MARK: - Cloud status (RemoteSyncSettingsView)
    var cloudStatusWaitingFirstUpload: String {
        switch language {
        case .fr: return "En attente du premier upload…"
        case .en: return "Waiting for first upload…"
        case .es: return "Esperando el primer envío…"
        }
    }
    func cloudStatusSyncedRelative(_ relative: String) -> String {
        switch language {
        case .fr: return "Synchronisé — dernier upload \(relative)"
        case .en: return "Synced — last upload \(relative)"
        case .es: return "Sincronizado — último envío \(relative)"
        }
    }
    var cloudStatusReady: String {
        switch language {
        case .fr: return "Compte iCloud OK, prêt à publier"
        case .en: return "iCloud account OK, ready to publish"
        case .es: return "Cuenta iCloud OK, lista para publicar"
        }
    }
    var cloudStatusPublishing: String {
        switch language {
        case .fr: return "Publication en cours…"
        case .en: return "Publishing…"
        case .es: return "Publicando…"
        }
    }
    var cloudReasonNoAccount: String {
        switch language {
        case .fr: return "Aucun compte iCloud sur ce Mac"
        case .en: return "No iCloud account on this Mac"
        case .es: return "No hay cuenta de iCloud en este Mac"
        }
    }
    var cloudReasonRestricted: String {
        switch language {
        case .fr: return "Compte iCloud restreint"
        case .en: return "iCloud account restricted"
        case .es: return "Cuenta de iCloud restringida"
        }
    }
    var cloudReasonUndetermined: String {
        switch language {
        case .fr: return "Statut iCloud indéterminé"
        case .en: return "iCloud status undetermined"
        case .es: return "Estado de iCloud indeterminado"
        }
    }
    var cloudReasonTempUnavailable: String {
        switch language {
        case .fr: return "iCloud temporairement indisponible"
        case .en: return "iCloud temporarily unavailable"
        case .es: return "iCloud temporalmente no disponible"
        }
    }
    var cloudReasonUnknown: String {
        switch language {
        case .fr: return "Statut iCloud inconnu"
        case .en: return "iCloud status unknown"
        case .es: return "Estado de iCloud desconocido"
        }
    }
    var tooltipEjectVolume: String {
        switch language {
        case .fr: return "Éjecter le volume"
        case .en: return "Eject volume"
        case .es: return "Expulsar el volumen"
        }
    }
    var confirmClearJournalTitle: String {
        switch language {
        case .fr: return "Effacer le journal d'activité ?"
        case .en: return "Clear the activity journal?"
        case .es: return "¿Borrar el registro de actividad?"
        }
    }
    var confirmClearJournalMessage: String {
        switch language {
        case .fr: return "Toutes les lignes du journal seront perdues. Cette action ne supprime pas les fichiers copiés."
        case .en: return "All journal entries will be removed. This does not delete any copied file."
        case .es: return "Todas las líneas del registro se perderán. Esta acción no elimina los archivos copiados."
        }
    }
    var confirmClearJournalAction: String {
        switch language {
        case .fr: return "Effacer"
        case .en: return "Clear"
        case .es: return "Borrar"
        }
    }

    var sectionDIT: String {
        switch language {
        case .fr: return "Structure DIT"
        case .en: return "DIT structure"
        case .es: return "Estructura DIT"
        }
    }
    var ditToggleTitle: String {
        switch language {
        case .fr: return "Activer l'arborescence DIT"
        case .en: return "Enable DIT folder structure"
        case .es: return "Activar estructura DIT"
        }
    }
    var ditToggleSubtitle: String {
        switch language {
        case .fr: return "Crée 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .en: return "Creates 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .es: return "Crea 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        }
    }
    var ditProjectPlaceholder: String {
        switch language {
        case .fr: return "Nom du projet (ex: FILM_X_2026)"
        case .en: return "Project name (e.g. FILM_X_2026)"
        case .es: return "Nombre del proyecto (ej: FILM_X_2026)"
        }
    }
    func ditPreview(project: String, date: String) -> String {
        "→ \(project)/01_RUSHES/\(date)/A_CAM/A001_xxxx/…"
    }
    func ditPreviewWithReel(project: String, date: String) -> String {
        "→ \(project)/01_RUSHES/\(date)/A_CAM/REEL_001/…"
    }
    var ditReelToggleTitle: String {
        switch language {
        case .fr: return "Sous-dossier REEL par dump"
        case .en: return "REEL subfolder per dump"
        case .es: return "Subcarpeta REEL por descarga"
        }
    }
    var ditReelToggleSubtitle: String {
        switch language {
        case .fr: return "Chaque déchargement de carte crée un REEL_001, REEL_002… numéroté par caméra"
        case .en: return "Each card dump creates REEL_001, REEL_002… numbered per camera"
        case .es: return "Cada descarga de tarjeta crea REEL_001, REEL_002… numerado por cámara"
        }
    }
    var ditProxyToggleTitle: String {
        switch language {
        case .fr: return "Copier les proxys caméra"
        case .en: return "Copy camera proxies"
        case .es: return "Copiar proxies de cámara"
        }
    }
    var ditProxyToggleSubtitle: String {
        switch language {
        case .fr: return "Route SUB/, PROXY/, suffixe S01… vers 03_PROXY/ au lieu de 01_RUSHES/"
        case .en: return "Routes SUB/, PROXY/, S01… files to 03_PROXY/ instead of 01_RUSHES/"
        case .es: return "Enruta SUB/, PROXY/, S01… a 03_PROXY/ en lugar de 01_RUSHES/"
        }
    }
    var ditReelResetButton: String {
        switch language {
        case .fr: return "Réinitialiser le compteur REEL"
        case .en: return "Reset REEL counter"
        case .es: return "Reiniciar contador REEL"
        }
    }
    var ditReelResetConfirmTitle: String {
        switch language {
        case .fr: return "Remettre le compteur REEL à 1 ?"
        case .en: return "Reset REEL counter to 1?"
        case .es: return "¿Reiniciar el contador REEL a 1?"
        }
    }
    var ditReelResetConfirmMessage: String {
        switch language {
        case .fr: return "Le prochain dump repartira de REEL_001 sur toutes les destinations configurées. Les dossiers REEL existants sur le disque ne sont pas supprimés."
        case .en: return "The next dump will start back at REEL_001 on every configured destination. Existing REEL folders on disk are not removed."
        case .es: return "La próxima descarga empezará de nuevo en REEL_001 en cada destino. Las carpetas REEL ya existentes no se eliminan."
        }
    }
    var ditReelResetConfirmAction: String {
        switch language {
        case .fr: return "Réinitialiser"
        case .en: return "Reset"
        case .es: return "Reiniciar"
        }
    }
    func logReelCounterReset(destinations: Int) -> String {
        switch language {
        case .fr: return "Compteur REEL réinitialisé sur \(destinations) destination(s)"
        case .en: return "REEL counter reset on \(destinations) destination(s)"
        case .es: return "Contador REEL reiniciado en \(destinations) destino(s)"
        }
    }
    var ditCameraTagLabel: String {
        switch language {
        case .fr: return "Caméra"
        case .en: return "Camera"
        case .es: return "Cámara"
        }
    }
    // MARK: - DIT settings tab
    var settingsTabDIT: String {
        switch language {
        case .fr: return "Structure DIT"
        case .en: return "DIT structure"
        case .es: return "Estructura DIT"
        }
    }
    var settingsDITFoldersHeader: String {
        switch language {
        case .fr: return "Noms des dossiers"
        case .en: return "Folder names"
        case .es: return "Nombres de carpetas"
        }
    }
    var settingsDITFoldersFooter: String {
        switch language {
        case .fr: return "Vide = valeur par défaut. Ces noms sont créés à la racine du dossier projet sur chaque destination."
        case .en: return "Blank = default. These folders are created at the project root on every destination."
        case .es: return "Vacío = valor predeterminado. Estas carpetas se crean en la raíz del proyecto en cada destino."
        }
    }
    var settingsDITLabelInfos: String {
        switch language {
        case .fr: return "Dossier infos"
        case .en: return "Info folder"
        case .es: return "Carpeta info"
        }
    }
    var settingsDITLabelRushes: String {
        switch language {
        case .fr: return "Dossier rushes"
        case .en: return "Rushes folder"
        case .es: return "Carpeta rushes"
        }
    }
    var settingsDITLabelMHL: String {
        switch language {
        case .fr: return "Dossier MHL"
        case .en: return "MHL folder"
        case .es: return "Carpeta MHL"
        }
    }
    var settingsDITLabelProxy: String {
        switch language {
        case .fr: return "Dossier proxy"
        case .en: return "Proxy folder"
        case .es: return "Carpeta proxy"
        }
    }
    var settingsDITLabelLUT: String {
        switch language {
        case .fr: return "Dossier LUT"
        case .en: return "LUT folder"
        case .es: return "Carpeta LUT"
        }
    }
    var settingsDITReportHeader: String {
        switch language {
        case .fr: return "Nom du rapport"
        case .en: return "Report filename"
        case .es: return "Nombre del informe"
        }
    }
    var settingsDITReportPrefix: String {
        switch language {
        case .fr: return "Préfixe du rapport DIT"
        case .en: return "DIT report prefix"
        case .es: return "Prefijo del informe DIT"
        }
    }
    func settingsDITReportPreview(prefix: String, date: String) -> String {
        switch language {
        case .fr: return "Nom final : `\(prefix)_\(date).pdf`"
        case .en: return "Final name: `\(prefix)_\(date).pdf`"
        case .es: return "Nombre final: `\(prefix)_\(date).pdf`"
        }
    }
    var settingsDITExtraHeader: String {
        switch language {
        case .fr: return "Dossiers supplémentaires"
        case .en: return "Extra folders"
        case .es: return "Carpetas adicionales"
        }
    }
    var settingsDITExtraFooter: String {
        switch language {
        case .fr: return "Crée des dossiers vides à la racine du projet en plus des 5 standards (ex: 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .en: return "Creates empty folders at the project root in addition to the 5 standard ones (e.g. 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .es: return "Crea carpetas vacías en la raíz del proyecto además de las 5 estándar (ej: 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        }
    }
    var settingsDITExtraPlaceholder: String {
        switch language {
        case .fr: return "Nom du dossier"
        case .en: return "Folder name"
        case .es: return "Nombre de carpeta"
        }
    }
    var settingsDITAddFolder: String {
        switch language {
        case .fr: return "Ajouter un dossier"
        case .en: return "Add folder"
        case .es: return "Añadir carpeta"
        }
    }
    var settingsDITReset: String {
        switch language {
        case .fr: return "Réinitialiser aux valeurs par défaut"
        case .en: return "Reset to defaults"
        case .es: return "Restablecer valores predeterminados"
        }
    }
    var menuStart: String {
        switch language {
        case .fr: return "Lancer"
        case .en: return "Start"
        case .es: return "Iniciar"
        }
    }
    var menuCancel: String {
        switch language {
        case .fr: return "Annuler"
        case .en: return "Cancel"
        case .es: return "Cancelar"
        }
    }
    var menuAddToQueue: String {
        switch language {
        case .fr: return "Ajouter à la file d'attente"
        case .en: return "Add to queue"
        case .es: return "Añadir a la cola"
        }
    }
    var menuClearQueue: String {
        switch language {
        case .fr: return "Vider la file"
        case .en: return "Clear queue"
        case .es: return "Vaciar la cola"
        }
    }
    var menuSpeedTest: String {
        switch language {
        case .fr: return "Test vitesse drive"
        case .en: return "Drive speed test"
        case .es: return "Prueba velocidad"
        }
    }
    var menuNoDest: String {
        switch language {
        case .fr: return "Aucune destination"
        case .en: return "No destination"
        case .es: return "Ningún destino"
        }
    }
    var menuToggleSim: String {
        switch language {
        case .fr: return "Simulation"
        case .en: return "Simulation"
        case .es: return "Simulación"
        }
    }
    var menuTogglePreserve: String {
        switch language {
        case .fr: return "Préserver la structure"
        case .en: return "Preserve structure"
        case .es: return "Conservar estructura"
        }
    }
    var menuToggleEjectAfter: String {
        switch language {
        case .fr: return "Éjecter après copie"
        case .en: return "Eject after copy"
        case .es: return "Expulsar tras copia"
        }
    }
    var menuToggleNotif: String {
        switch language {
        case .fr: return "Notification système"
        case .en: return "System notification"
        case .es: return "Notificación del sistema"
        }
    }
    var menuToggleSkipSystem: String {
        switch language {
        case .fr: return "Ignorer fichiers système"
        case .en: return "Skip system files"
        case .es: return "Omitir archivos de sistema"
        }
    }
    var menuToggleOrganize: String {
        switch language {
        case .fr: return "Organiser par date"
        case .en: return "Organize by date"
        case .es: return "Organizar por fecha"
        }
    }
    var menuToggleThumbs: String {
        switch language {
        case .fr: return "Vignettes dans le PDF"
        case .en: return "Thumbnails in PDF"
        case .es: return "Miniaturas en PDF"
        }
    }
    var menuToggleDuplicates: String {
        switch language {
        case .fr: return "Détection des doublons"
        case .en: return "Duplicate detection"
        case .es: return "Detección duplicados"
        }
    }
    var menuAlgo: String {
        switch language {
        case .fr: return "Algorithme"
        case .en: return "Algorithm"
        case .es: return "Algoritmo"
        }
    }
    var menuBandwidthLimit: String {
        switch language {
        case .fr: return "Limite de débit"
        case .en: return "Bandwidth limit"
        case .es: return "Límite ancho"
        }
    }
    var menuVerifyMHL: String {
        switch language {
        case .fr: return "Vérifier MHL…"
        case .en: return "Verify MHL…"
        case .es: return "Verificar MHL…"
        }
    }
    var menuExportMHLv1: String {
        switch language {
        case .fr: return "Exporter MHL v1…"
        case .en: return "Export MHL v1…"
        case .es: return "Exportar MHL v1…"
        }
    }
    var menuExportASCMHL: String {
        switch language {
        case .fr: return "Exporter ASCMHL v2…"
        case .en: return "Export ASCMHL v2…"
        case .es: return "Exportar ASCMHL v2…"
        }
    }
    var menuExportCSV: String {
        switch language {
        case .fr: return "Exporter CSV…"
        case .en: return "Export CSV…"
        case .es: return "Exportar CSV…"
        }
    }
    var menuExportHTML: String {
        switch language {
        case .fr: return "Exporter HTML…"
        case .en: return "Export HTML…"
        case .es: return "Exportar HTML…"
        }
    }
    var menuHistoryOpen2: String {
        switch language {
        case .fr: return "Historique…"
        case .en: return "History…"
        case .es: return "Historial…"
        }
    }
    var menuClearLog: String {
        switch language {
        case .fr: return "Effacer le journal"
        case .en: return "Clear log"
        case .es: return "Limpiar registro"
        }
    }
    var menuSaveCurrent: String {
        switch language {
        case .fr: return "Enregistrer le profil actuel…"
        case .en: return "Save current preset…"
        case .es: return "Guardar perfil actual…"
        }
    }
    var menuManagePresets: String {
        switch language {
        case .fr: return "Gérer les profils…"
        case .en: return "Manage presets…"
        case .es: return "Gestionar perfiles…"
        }
    }
    var menuNoPreset: String {
        switch language {
        case .fr: return "Aucun profil enregistré"
        case .en: return "No saved preset"
        case .es: return "Ningún perfil"
        }
    }
    var menuUnlimited: String {
        switch language {
        case .fr: return "Illimité"
        case .en: return "Unlimited"
        case .es: return "Ilimitado"
        }
    }

    // MARK: - Watch + webhook + tags

    func logWatchAutoAdded(_ name: String) -> String {
        switch language {
        case .fr: return "Surveillance — \(name) ajouté automatiquement"
        case .en: return "Watch — auto-added \(name)"
        case .es: return "Vigilancia — \(name) añadido automáticamente"
        }
    }
    var logWatchAutoStarted: String {
        switch language {
        case .fr: return "Surveillance — lancement automatique"
        case .en: return "Watch — auto-started copy"
        case .es: return "Vigilancia — copia iniciada automáticamente"
        }
    }
    var logWebhookSent: String {
        switch language {
        case .fr: return "Webhook envoyé"
        case .en: return "Webhook sent"
        case .es: return "Webhook enviado"
        }
    }
    // MARK: - License

    var sectionLicense: String {
        switch language {
        case .fr: return "Licence"
        case .en: return "License"
        case .es: return "Licencia"
        }
    }
    var licenseStateTrial: String {
        switch language {
        case .fr: return "Essai gratuit"
        case .en: return "Free trial"
        case .es: return "Prueba gratuita"
        }
    }
    func licenseTrialRemaining(days: Int, transfers: Int) -> String {
        switch language {
        case .fr: return "\(days) j · \(transfers) transferts restants"
        case .en: return "\(days)d · \(transfers) transfers left"
        case .es: return "\(days) d · \(transfers) transferencias restantes"
        }
    }
    var licenseStateExpired: String {
        switch language {
        case .fr: return "Essai expiré"
        case .en: return "Trial expired"
        case .es: return "Prueba expirada"
        }
    }
    var licenseStateActive: String {
        switch language {
        case .fr: return "Licence active"
        case .en: return "License active"
        case .es: return "Licencia activa"
        }
    }
    var licenseFieldEmail: String {
        switch language {
        case .fr: return "Email d'achat"
        case .en: return "Purchase email"
        case .es: return "Email de compra"
        }
    }
    var licenseFieldKey: String {
        switch language {
        case .fr: return "Clé de licence"
        case .en: return "License key"
        case .es: return "Clave de licencia"
        }
    }
    var licenseActivate: String {
        switch language {
        case .fr: return "Activer"
        case .en: return "Activate"
        case .es: return "Activar"
        }
    }
    var licenseInvalid: String {
        switch language {
        case .fr: return "Email ou clé invalide"
        case .en: return "Invalid email or key"
        case .es: return "Email o clave no válidos"
        }
    }
    var licenseDeactivate: String {
        switch language {
        case .fr: return "Désactiver sur ce poste"
        case .en: return "Deactivate on this machine"
        case .es: return "Desactivar en este equipo"
        }
    }
    func licenseBuyAt(_ price: String) -> String {
        switch language {
        case .fr: return "Acheter — \(price)"
        case .en: return "Buy — \(price)"
        case .es: return "Comprar — \(price)"
        }
    }
    var licenseTwoMachineHint: String {
        switch language {
        case .fr: return "Une licence couvre jusqu'à 2 postes."
        case .en: return "One license covers up to 2 machines."
        case .es: return "Una licencia cubre hasta 2 equipos."
        }
    }
    var logLicenseExpired: String {
        switch language {
        case .fr: return "Essai expiré — entrez une licence pour continuer"
        case .en: return "Trial expired — enter a license to continue"
        case .es: return "Prueba expirada — introduce una licencia"
        }
    }
    var badgeTrial: String {
        switch language {
        case .fr: return "ESSAI"
        case .en: return "TRIAL"
        case .es: return "PRUEBA"
        }
    }
    var badgeExpired: String {
        switch language {
        case .fr: return "EXPIRÉ"
        case .en: return "EXPIRED"
        case .es: return "EXPIRADO"
        }
    }
    var badgeLicensed: String {
        switch language {
        case .fr: return "LICENCE"
        case .en: return "LICENSED"
        case .es: return "LICENCIA"
        }
    }

    var quickToggleWatch: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        }
    }
    var quickToggleAutoStart: String {
        switch language {
        case .fr: return "Auto-start"
        case .en: return "Auto-start"
        case .es: return "Inicio automático"
        }
    }
    var quickToggleAutoEject: String {
        switch language {
        case .fr: return "Auto eject"
        case .en: return "Auto eject"
        case .es: return "Expulsión auto."
        }
    }
    var quickToggleSkipDuplicates: String {
        switch language {
        case .fr: return "Doublons"
        case .en: return "Dupes"
        case .es: return "Duplicados"
        }
    }
    var settingsParallelSection: String {
        switch language {
        case .fr: return "Copie multi-cartes"
        case .en: return "Multi-card copy"
        case .es: return "Copia multi-tarjeta"
        }
    }
    var settingsParallelToggle: String {
        switch language {
        case .fr: return "Copier les sources en parallèle"
        case .en: return "Copy sources in parallel"
        case .es: return "Copiar orígenes en paralelo"
        }
    }
    var settingsParallelFooter: String {
        switch language {
        case .fr: return "Chaque carte source a son propre pipeline de copie et de vérification — plusieurs cartes se déchargent en même temps. Recommandé uniquement vers un SSD/NVMe ; sur un disque dur mécanique, la copie séquentielle reste plus rapide."
        case .en: return "Each source card gets its own copy + verification pipeline — several cards offload at the same time. Recommended only toward an SSD/NVMe; on a spinning hard drive, sequential copy stays faster."
        case .es: return "Cada tarjeta origen tiene su propio flujo de copia y verificación — varias tarjetas se descargan a la vez. Recomendado solo hacia un SSD/NVMe; en un disco duro mecánico, la copia secuencial sigue siendo más rápida."
        }
    }
    var menuWatchSection: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        }
    }
    var menuWatchAutoAdd: String {
        switch language {
        case .fr: return "Ajout automatique des cartes"
        case .en: return "Auto-add cards"
        case .es: return "Añadir tarjetas automáticamente"
        }
    }
    var menuWatchAutoStart: String {
        switch language {
        case .fr: return "Lancement automatique"
        case .en: return "Auto-start copy"
        case .es: return "Inicio automático"
        }
    }
    var menuExportJournal: String {
        switch language {
        case .fr: return "Exporter le journal…"
        case .en: return "Export log…"
        case .es: return "Exportar registro…"
        }
    }
    var panelExportJournal: String {
        switch language {
        case .fr: return "Exporter le journal"
        case .en: return "Export log"
        case .es: return "Exportar registro"
        }
    }
    var buttonJournal: String {
        switch language {
        case .fr: return "Journal"
        case .en: return "Log"
        case .es: return "Registro"
        }
    }
    var journalHeaderTitle: String {
        switch language {
        case .fr: return "MisiCopy — Journal d'activité"
        case .en: return "MisiCopy — Activity log"
        case .es: return "MisiCopy — Registro de actividad"
        }
    }
    func journalHeaderExportedAt(_ iso: String) -> String {
        switch language {
        case .fr: return "Exporté le \(iso)"
        case .en: return "Exported at \(iso)"
        case .es: return "Exportado el \(iso)"
        }
    }
    func journalHeaderEntries(_ n: Int) -> String {
        switch language {
        case .fr: return "\(n) entrée(s)"
        case .en: return n == 1 ? "1 entry" : "\(n) entries"
        case .es: return "\(n) entrada(s)"
        }
    }

    // MARK: - Confort pro (Phase P3+)

    var logPaused: String {
        switch language {
        case .fr: return "Copie en pause"
        case .en: return "Copy paused"
        case .es: return "Copia en pausa"
        }
    }
    var logResumed: String {
        switch language {
        case .fr: return "Reprise de la copie"
        case .en: return "Copy resumed"
        case .es: return "Copia reanudada"
        }
    }
    var actionPause: String {
        switch language {
        case .fr: return "Pause"
        case .en: return "Pause"
        case .es: return "Pausar"
        }
    }
    var actionResume: String {
        switch language {
        case .fr: return "Reprendre"
        case .en: return "Resume"
        case .es: return "Reanudar"
        }
    }
    func logDuplicateSkipped(_ file: String, _ destination: String) -> String {
        switch language {
        case .fr: return "\(file) — déjà présent à \(destination), copie évitée"
        case .en: return "\(file) — already present at \(destination), copy skipped"
        case .es: return "\(file) — ya presente en \(destination), copia omitida"
        }
    }
    func logSpeedTestStart(_ name: String) -> String {
        switch language {
        case .fr: return "Test vitesse — \(name)…"
        case .en: return "Speed test — \(name)…"
        case .es: return "Test velocidad — \(name)…"
        }
    }
    func logSpeedTestResult(folder: String, writeMBs: Double, readMBs: Double) -> String {
        let w = String(format: "%.0f", writeMBs)
        let r = String(format: "%.0f", readMBs)
        switch language {
        case .fr: return "\(folder) — écriture \(w) MB/s, lecture \(r) MB/s"
        case .en: return "\(folder) — write \(w) MB/s, read \(r) MB/s"
        case .es: return "\(folder) — escritura \(w) MB/s, lectura \(r) MB/s"
        }
    }
    func logSpeedTestFailed(_ reason: String) -> String {
        switch language {
        case .fr: return "Test vitesse échoué — \(reason)"
        case .en: return "Speed test failed — \(reason)"
        case .es: return "Test velocidad fallido — \(reason)"
        }
    }

    // MARK: - History / bandwidth / status item

    var menuHistory: String {
        switch language {
        case .fr: return "Historique"
        case .en: return "History"
        case .es: return "Historial"
        }
    }
    var menuHistoryOpen: String {
        switch language {
        case .fr: return "Ouvrir l'historique…"
        case .en: return "Open history…"
        case .es: return "Abrir historial…"
        }
    }
    var historyEmpty: String {
        switch language {
        case .fr: return "Aucune session enregistrée"
        case .en: return "No session recorded"
        case .es: return "Ninguna sesión registrada"
        }
    }
    var buttonClearHistory: String {
        switch language {
        case .fr: return "Tout effacer"
        case .en: return "Clear all"
        case .es: return "Borrar todo"
        }
    }
    var toggleStatusItem: String {
        switch language {
        case .fr: return "Icône dans la barre des menus"
        case .en: return "Show menu bar icon"
        case .es: return "Icono en barra de menús"
        }
    }
    var labelBandwidth: String {
        switch language {
        case .fr: return "Limite de débit"
        case .en: return "Bandwidth limit"
        case .es: return "Límite de ancho"
        }
    }
    var bandwidthUnlimited: String {
        switch language {
        case .fr: return "Illimité"
        case .en: return "Unlimited"
        case .es: return "Ilimitado"
        }
    }

    // MARK: - Queue & resume

    var sectionQueue: String {
        switch language {
        case .fr: return "File d'attente"
        case .en: return "Queue"
        case .es: return "Cola"
        }
    }
    var buttonAddToQueue: String {
        switch language {
        case .fr: return "Ajouter à la file"
        case .en: return "Add to queue"
        case .es: return "Añadir a la cola"
        }
    }
    var buttonClearQueue: String {
        switch language {
        case .fr: return "Vider"
        case .en: return "Clear"
        case .es: return "Vaciar"
        }
    }
    func logJobQueued(_ summary: String) -> String {
        switch language {
        case .fr: return "Tâche ajoutée à la file — \(summary)"
        case .en: return "Job queued — \(summary)"
        case .es: return "Tarea encolada — \(summary)"
        }
    }
    func logQueueStarting(_ summary: String) -> String {
        switch language {
        case .fr: return "Démarrage de la tâche suivante — \(summary)"
        case .en: return "Starting next job — \(summary)"
        case .es: return "Iniciando siguiente tarea — \(summary)"
        }
    }
    var logQueueNeedsSrcDest: String {
        switch language {
        case .fr: return "Impossible de mettre en file — source ou destination manquante"
        case .en: return "Cannot queue — source or destination missing"
        case .es: return "No se puede encolar — falta origen o destino"
        }
    }

    var sessionResumeTitle: String {
        switch language {
        case .fr: return "Session précédente détectée"
        case .en: return "Previous session detected"
        case .es: return "Sesión anterior detectada"
        }
    }
    func sessionResumeSubtitle(savedAt: Date) -> String {
        let date = formatDateTime(savedAt)
        switch language {
        case .fr: return "Restaurer sources, destinations et options — \(date)"
        case .en: return "Restore sources, destinations and options — \(date)"
        case .es: return "Restaurar orígenes, destinos y opciones — \(date)"
        }
    }
    var buttonResume: String {
        switch language {
        case .fr: return "Reprendre"
        case .en: return "Resume"
        case .es: return "Reanudar"
        }
    }
    var logSessionResumed: String {
        switch language {
        case .fr: return "Session précédente restaurée"
        case .en: return "Previous session restored"
        case .es: return "Sesión anterior restaurada"
        }
    }

    // MARK: - Presets / Verify

    var toggleOrganizeByDate: String {
        switch language {
        case .fr: return "Organiser par date"
        case .en: return "Organize by date"
        case .es: return "Organizar por fecha"
        }
    }
    var menuPresets: String {
        switch language {
        case .fr: return "Profils"
        case .en: return "Presets"
        case .es: return "Perfiles"
        }
    }
    var menuPresetsApply: String {
        switch language {
        case .fr: return "Appliquer un profil"
        case .en: return "Apply preset"
        case .es: return "Aplicar perfil"
        }
    }
    var menuPresetsSave: String {
        switch language {
        case .fr: return "Enregistrer le profil actuel…"
        case .en: return "Save current preset…"
        case .es: return "Guardar perfil actual…"
        }
    }
    var menuPresetsManage: String {
        switch language {
        case .fr: return "Gérer les profils…"
        case .en: return "Manage presets…"
        case .es: return "Gestionar perfiles…"
        }
    }
    var menuPresetsEmpty: String {
        switch language {
        case .fr: return "Aucun profil enregistré"
        case .en: return "No saved preset"
        case .es: return "Ningún perfil guardado"
        }
    }
    var dialogPresetNameTitle: String {
        switch language {
        case .fr: return "Nom du profil"
        case .en: return "Preset name"
        case .es: return "Nombre del perfil"
        }
    }
    var dialogPresetNamePrompt: String {
        switch language {
        case .fr: return "Ex : Tournage A-cam — xxHash + éjection"
        case .en: return "E.g.: A-cam shoot — xxHash + eject"
        case .es: return "Ej.: Rodaje A-cam — xxHash + expulsar"
        }
    }
    var buttonSave: String {
        switch language {
        case .fr: return "Enregistrer"
        case .en: return "Save"
        case .es: return "Guardar"
        }
    }
    var buttonCancel: String {
        switch language {
        case .fr: return "Annuler"
        case .en: return "Cancel"
        case .es: return "Cancelar"
        }
    }
    var buttonDelete: String {
        switch language {
        case .fr: return "Supprimer"
        case .en: return "Delete"
        case .es: return "Eliminar"
        }
    }
    var buttonClose: String {
        switch language {
        case .fr: return "Fermer"
        case .en: return "Close"
        case .es: return "Cerrar"
        }
    }
    func logPresetApplied(_ name: String) -> String {
        switch language {
        case .fr: return "Profil appliqué — \(name)"
        case .en: return "Preset applied — \(name)"
        case .es: return "Perfil aplicado — \(name)"
        }
    }
    func logPresetSaved(_ name: String) -> String {
        switch language {
        case .fr: return "Profil enregistré — \(name)"
        case .en: return "Preset saved — \(name)"
        case .es: return "Perfil guardado — \(name)"
        }
    }

    var buttonVerifyMHL: String {
        switch language {
        case .fr: return "Vérifier MHL…"
        case .en: return "Verify MHL…"
        case .es: return "Verificar MHL…"
        }
    }
    var panelVerifyTitle: String {
        switch language {
        case .fr: return "Choisir un fichier MHL à vérifier"
        case .en: return "Choose an MHL file to verify"
        case .es: return "Elegir un archivo MHL para verificar"
        }
    }
    var panelChooseSourceTitle: String {
        switch language {
        case .fr: return "Dossier source contenant les fichiers"
        case .en: return "Source folder containing the files"
        case .es: return "Carpeta origen con los archivos"
        }
    }
    func logVerifyStart(_ name: String) -> String {
        switch language {
        case .fr: return "Vérification du MHL — \(name)"
        case .en: return "Verifying MHL — \(name)"
        case .es: return "Verificando MHL — \(name)"
        }
    }
    func logVerifyParseFailed(_ reason: String) -> String {
        switch language {
        case .fr: return "Lecture du MHL impossible — \(reason)"
        case .en: return "Could not parse MHL — \(reason)"
        case .es: return "No se pudo leer el MHL — \(reason)"
        }
    }
    func logVerifyMatch(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — checksum OK"
        case .en: return "\(name) — checksum OK"
        case .es: return "\(name) — checksum OK"
        }
    }
    func logVerifyMismatch(_ name: String, expected: String, found: String) -> String {
        let e = String(expected.prefix(12))
        let f = String(found.prefix(12))
        switch language {
        case .fr: return "\(name) — corrompu (attendu \(e)… reçu \(f)…)"
        case .en: return "\(name) — corrupted (expected \(e)… got \(f)…)"
        case .es: return "\(name) — corrupto (esperado \(e)… recibido \(f)…)"
        }
    }
    func logVerifyMissing(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — fichier manquant"
        case .en: return "\(name) — missing file"
        case .es: return "\(name) — archivo faltante"
        }
    }
    func logVerifyReadError(_ name: String, _ reason: String) -> String {
        switch language {
        case .fr: return "\(name) — erreur lecture — \(reason)"
        case .en: return "\(name) — read error — \(reason)"
        case .es: return "\(name) — error lectura — \(reason)"
        }
    }
    func logVerifyDoneOK(_ count: Int) -> String {
        switch language {
        case .fr: return "Vérification terminée — \(count) fichier(s) intacts"
        case .en: return "Verification finished — \(count) file(s) intact"
        case .es: return "Verificación terminada — \(count) archivo(s) intactos"
        }
    }
    func logVerifyDoneWithErrors(_ count: Int) -> String {
        switch language {
        case .fr: return "Vérification terminée — \(count) problème(s) détecté(s)"
        case .en: return "Verification finished — \(count) issue(s) detected"
        case .es: return "Verificación terminada — \(count) problema(s) detectado(s)"
        }
    }

    func logVolumeProbe(name: String, internal isInternal: Bool, removable: Bool, ejectable: Bool) -> String {
        let i = isInternal ? "✓" : "✗"
        let r = removable ? "✓" : "✗"
        let e = ejectable ? "✓" : "✗"
        switch language {
        case .fr: return "Volume \(name) — interne:\(i) amovible:\(r) éjectable:\(e)"
        case .en: return "Volume \(name) — internal:\(i) removable:\(r) ejectable:\(e)"
        case .es: return "Volumen \(name) — interno:\(i) extraíble:\(r) expulsable:\(e)"
        }
    }
    func logEjectFailed(_ name: String, _ reason: String) -> String {
        switch language {
        case .fr: return "Éjection impossible — \(name) — \(reason)"
        case .en: return "Eject failed — \(name) — \(reason)"
        case .es: return "Expulsión fallida — \(name) — \(reason)"
        }
    }
    func logEjectSkippedErrors(_ name: String) -> String {
        switch language {
        case .fr: return "Éjection annulée pour \(name) — erreurs durant la copie"
        case .en: return "Eject cancelled for \(name) — errors during copy"
        case .es: return "Expulsión cancelada para \(name) — errores durante la copia"
        }
    }
    var logNoRemovableSource: String {
        switch language {
        case .fr: return "Éjection ignorée — aucune source amovible détectée"
        case .en: return "Eject skipped — no removable source detected"
        case .es: return "Expulsión omitida — sin origen extraíble detectado"
        }
    }
    func notifSuccess(_ verified: Int, _ total: Int) -> String {
        switch language {
        case .fr: return "Copie terminée — \(verified)/\(total) vérifié(s)"
        case .en: return "Copy finished — \(verified)/\(total) verified"
        case .es: return "Copia terminada — \(verified)/\(total) verificados"
        }
    }
    func notifFailure(_ failed: Int) -> String {
        switch language {
        case .fr: return "Terminé avec \(failed) erreur(s)"
        case .en: return "Finished with \(failed) error(s)"
        case .es: return "Terminado con \(failed) error(es)"
        }
    }
    var labelSpeed: String {
        switch language {
        case .fr: return "Vitesse"
        case .en: return "Speed"
        case .es: return "Velocidad"
        }
    }
    var toggleEject: String {
        switch language {
        case .fr: return "Éjecter la carte après copie"
        case .en: return "Eject card after copy"
        case .es: return "Expulsar tarjeta tras copia"
        }
    }
    var toggleNotify: String {
        switch language {
        case .fr: return "Notification système"
        case .en: return "System notification"
        case .es: return "Notificación del sistema"
        }
    }
    var toggleSkipSystem: String {
        switch language {
        case .fr: return "Ignorer fichiers système"
        case .en: return "Skip system files"
        case .es: return "Omitir archivos de sistema"
        }
    }
    var sourcesEmptyTitle: String {
        switch language {
        case .fr: return "Aucune source"
        case .en: return "No source"
        case .es: return "Ningún origen"
        }
    }
    var sourcesEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez une ou plusieurs sources — cartes ou dossiers"
        case .en: return "Drop one or several sources — cards or folders"
        case .es: return "Arrastra uno o varios orígenes — tarjetas o carpetas"
        }
    }
    var sourceAddTitle: String {
        switch language {
        case .fr: return "Ajouter une source"
        case .en: return "Add a source"
        case .es: return "Añadir un origen"
        }
    }
    func cardDetected(_ name: String) -> String {
        switch language {
        case .fr: return "Carte détectée — \(name)"
        case .en: return "Card detected — \(name)"
        case .es: return "Tarjeta detectada — \(name)"
        }
    }
    var addAsSource: String {
        switch language {
        case .fr: return "Ajouter comme source"
        case .en: return "Add as source"
        case .es: return "Añadir como origen"
        }
    }
    var dismiss: String {
        switch language {
        case .fr: return "Ignorer"
        case .en: return "Dismiss"
        case .es: return "Ignorar"
        }
    }

    // MARK: - File status labels
    func fileStatusLabel(_ status: FileStatus) -> String {
        switch (status, language) {
        case (.pending, .fr): return "En attente"
        case (.pending, .en): return "Pending"
        case (.pending, .es): return "En espera"
        case (.copying, .fr): return "Copie…"
        case (.copying, .en): return "Copying…"
        case (.copying, .es): return "Copiando…"
        case (.verifying, .fr): return "Vérification…"
        case (.verifying, .en): return "Verifying…"
        case (.verifying, .es): return "Verificando…"
        case (.copied, .fr): return "Copié"
        case (.copied, .en): return "Copied"
        case (.copied, .es): return "Copiado"
        case (.verified, .fr): return "Vérifié"
        case (.verified, .en): return "Verified"
        case (.verified, .es): return "Verificado"
        case (.failed(let reason), .fr): return "Erreur — \(reason)"
        case (.failed(let reason), .en): return "Error — \(reason)"
        case (.failed(let reason), .es): return "Error — \(reason)"
        case (.skipped, .fr): return "Ignoré"
        case (.skipped, .en): return "Skipped"
        case (.skipped, .es): return "Omitido"
        }
    }
}
