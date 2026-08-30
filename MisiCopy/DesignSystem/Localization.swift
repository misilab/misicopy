//
//  Localization.swift
//  MisiCopy
//
//  Centralized translations for FR / EN / ES / DE / IT.
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
        case .de: return Locale(identifier: "de_DE")
        case .it: return Locale(identifier: "it_IT")
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
        case .de: return "Sichere Kopie mit Verifikation"
        case .it: return "Copia sicura con verifica"
        }
    }

    // MARK: - Sections
    var sectionMode: String {
        switch language {
        case .fr: return "Mode de copie"
        case .en: return "Copy mode"
        case .es: return "Modo de copia"
        case .de: return "Kopiermodus"
        case .it: return "Modalità di copia"
        }
    }
    var sectionSource: String {
        switch language {
        case .fr: return "Source"
        case .en: return "Source"
        case .es: return "Origen"
        case .de: return "Quelle"
        case .it: return "Sorgente"
        }
    }
    var sectionDestinations: String {
        switch language {
        case .fr: return "Destinations"
        case .en: return "Destinations"
        case .es: return "Destinos"
        case .de: return "Ziele"
        case .it: return "Destinazioni"
        }
    }
    var sectionJournal: String {
        switch language {
        case .fr: return "Journal"
        case .en: return "Log"
        case .es: return "Registro"
        case .de: return "Protokoll"
        case .it: return "Registro"
        }
    }

    // MARK: - Modes
    func modeTitle(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Copie + vérification"
        case (.verified, .en): return "Copy + verification"
        case (.verified, .es): return "Copia + verificación"
        case (.verified, .de): return "Copia + verificación"
        case (.verified, .it): return "Copia + verificación"
        case (.doubleVerified, .fr): return "Copie + double vérification"
        case (.doubleVerified, .en): return "Copy + double verification"
        case (.doubleVerified, .es): return "Copia + doble verificación"
        case (.doubleVerified, .de): return "Copia + doble verificación"
        case (.doubleVerified, .it): return "Copia + doble verificación"
        case (.fast, .fr): return "Copie rapide"
        case (.fast, .en): return "Fast copy"
        case (.fast, .es): return "Copia rápida"
        case (.fast, .de): return "Copia rápida"
        case (.fast, .it): return "Copia rápida"
        case (.verifyOnly, .fr): return "Vérification seule"
        case (.verifyOnly, .en): return "Verify only"
        case (.verifyOnly, .es): return "Solo verificación"
        case (.verifyOnly, .de): return "Solo verificación"
        case (.verifyOnly, .it): return "Solo verificación"
        }
    }
    func modeVerificationDetail(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Hash source + hash destination → comparaison"
        case (.verified, .en): return "Source hash + destination hash → comparison"
        case (.verified, .es): return "Hash origen + hash destino → comparación"
        case (.verified, .de): return "Hash origen + hash destino → comparación"
        case (.verified, .it): return "Hash origen + hash destino → comparación"
        case (.doubleVerified, .fr): return "Hash source + dest + re-hash source (3 lectures)"
        case (.doubleVerified, .en): return "Source hash + dest + re-hash source (3 reads)"
        case (.doubleVerified, .es): return "Hash origen + dest + re-hash origen (3 lecturas)"
        case (.doubleVerified, .de): return "Hash origen + dest + re-hash origen (3 lecturas)"
        case (.doubleVerified, .it): return "Hash origen + dest + re-hash origen (3 lecturas)"
        case (.fast, .fr): return "Aucune vérification — copie seule"
        case (.fast, .en): return "No verification — copy only"
        case (.fast, .es): return "Sin verificación — solo copia"
        case (.fast, .de): return "Sin verificación — solo copia"
        case (.fast, .it): return "Sin verificación — solo copia"
        case (.verifyOnly, .fr): return "Hash source + hash de la copie existante → comparaison"
        case (.verifyOnly, .en): return "Source hash + existing copy hash → comparison"
        case (.verifyOnly, .es): return "Hash origen + hash de la copia existente → comparación"
        case (.verifyOnly, .de): return "Hash origen + hash de la copia existente → comparación"
        case (.verifyOnly, .it): return "Hash origen + hash de la copia existente → comparación"
        }
    }
    func modeSubtitle(_ mode: CopyMode) -> String {
        switch (mode, language) {
        case (.verified, .fr): return "Checksum après copie — recommandé"
        case (.verified, .en): return "Checksum after copy — recommended"
        case (.verified, .es): return "Checksum tras la copia — recomendado"
        case (.verified, .de): return "Checksum tras la copia — recomendado"
        case (.verified, .it): return "Checksum tras la copia — recomendado"
        case (.doubleVerified, .fr): return "Re-lit la source et la destination pour comparer"
        case (.doubleVerified, .en): return "Re-reads source and destination to compare"
        case (.doubleVerified, .es): return "Vuelve a leer origen y destino para comparar"
        case (.doubleVerified, .de): return "Vuelve a leer origen y destino para comparar"
        case (.doubleVerified, .it): return "Vuelve a leer origen y destino para comparar"
        case (.fast, .fr): return "Sans vérification — déconseillé pour archive"
        case (.fast, .en): return "No verification — not recommended for archive"
        case (.fast, .es): return "Sin verificación — no recomendado para archivo"
        case (.fast, .de): return "Sin verificación — no recomendado para archivo"
        case (.fast, .it): return "Sin verificación — no recomendado para archivo"
        case (.verifyOnly, .fr): return "Compare source et copie existante — ne copie rien"
        case (.verifyOnly, .en): return "Compares source and existing copy — copies nothing"
        case (.verifyOnly, .es): return "Compara origen y copia existente — no copia nada"
        case (.verifyOnly, .de): return "Compara origen y copia existente — no copia nada"
        case (.verifyOnly, .it): return "Compara origen y copia existente — no copia nada"
        }
    }

    // MARK: - Toggles & picker
    var toggleSimulation: String {
        switch language {
        case .fr: return "Simulation (aucun fichier copié)"
        case .en: return "Simulation (no file copied)"
        case .es: return "Simulación (ningún archivo copiado)"
        case .de: return "Simulation (keine Datei kopiert)"
        case .it: return "Simulazione (nessun file copiato)"
        }
    }
    var togglePreserve: String {
        switch language {
        case .fr: return "Préserver la structure"
        case .en: return "Preserve structure"
        case .es: return "Conservar estructura"
        case .de: return "Struktur beibehalten"
        case .it: return "Mantieni struttura"
        }
    }
    var labelAlgorithm: String {
        switch language {
        case .fr: return "Algorithme"
        case .en: return "Algorithm"
        case .es: return "Algoritmo"
        case .de: return "Algorithmus"
        case .it: return "Algoritmo"
        }
    }
    var labelElapsed: String {
        switch language {
        case .fr: return "Écoulé"
        case .en: return "Elapsed"
        case .es: return "Transcurrido"
        case .de: return "Vergangen"
        case .it: return "Trascorso"
        }
    }
    var labelRemaining: String {
        switch language {
        case .fr: return "Restant"
        case .en: return "Remaining"
        case .es: return "Restante"
        case .de: return "Verbleibend"
        case .it: return "Rimanente"
        }
    }

    // MARK: - Source & destinations
    var sourceEmptyTitle: String {
        switch language {
        case .fr: return "Aucun dossier sélectionné"
        case .en: return "No folder selected"
        case .es: return "Ninguna carpeta seleccionada"
        case .de: return "Kein Ordner ausgewählt"
        case .it: return "Nessuna cartella selezionata"
        }
    }
    var sourceEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez un dossier ici ou cliquez sur Choisir"
        case .en: return "Drop a folder here or click Choose"
        case .es: return "Arrastra una carpeta o haz clic en Elegir"
        case .de: return "Ordner hier ablegen oder Auswählen klicken"
        case .it: return "Trascina una cartella qui o fai clic su Scegli"
        }
    }
    var destEmptyTitle: String {
        switch language {
        case .fr: return "Aucune destination"
        case .en: return "No destination"
        case .es: return "Ningún destino"
        case .de: return "Kein Ziel"
        case .it: return "Nessuna destinazione"
        }
    }
    var destEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez un ou plusieurs dossiers — copie simultanée"
        case .en: return "Drop one or several folders — simultaneous copy"
        case .es: return "Arrastra una o varias carpetas — copia simultánea"
        case .de: return "Einen oder mehrere Ordner ablegen — gleichzeitige Kopie"
        case .it: return "Trascina una o più cartelle — copia simultanea"
        }
    }
    var destAddTitle: String {
        switch language {
        case .fr: return "Ajouter une destination"
        case .en: return "Add a destination"
        case .es: return "Añadir un destino"
        case .de: return "Ziel hinzufügen"
        case .it: return "Aggiungi destinazione"
        }
    }
    var destAddSubtitle: String {
        switch language {
        case .fr: return "Glissez un dossier ici"
        case .en: return "Drop a folder here"
        case .es: return "Arrastra una carpeta aquí"
        case .de: return "Ordner hier ablegen"
        case .it: return "Trascina una cartella qui"
        }
    }

    // MARK: - Buttons / actions
    var buttonChoose: String {
        switch language {
        case .fr: return "Choisir"
        case .en: return "Choose"
        case .es: return "Elegir"
        case .de: return "Auswählen"
        case .it: return "Scegli"
        }
    }
    var buttonAdd: String {
        switch language {
        case .fr: return "Ajouter"
        case .en: return "Add"
        case .es: return "Añadir"
        case .de: return "Hinzufügen"
        case .it: return "Aggiungi"
        }
    }
    var buttonClear: String {
        switch language {
        case .fr: return "Effacer"
        case .en: return "Clear"
        case .es: return "Limpiar"
        case .de: return "Leeren"
        case .it: return "Pulisci"
        }
    }
    var buttonExportMHL: String {
        switch language {
        case .fr: return "Exporter MHL…"
        case .en: return "Export MHL…"
        case .es: return "Exportar MHL…"
        case .de: return "Export MHL…"
        case .it: return "Export MHL…"
        }
    }
    var panelSelect: String {
        switch language {
        case .fr: return "Sélectionner"
        case .en: return "Select"
        case .es: return "Seleccionar"
        case .de: return "Auswählen"
        case .it: return "Seleziona"
        }
    }
    var panelExportTitle: String {
        switch language {
        case .fr: return "Exporter le rapport MHL"
        case .en: return "Export MHL report"
        case .es: return "Exportar informe MHL"
        case .de: return "MHL-Bericht exportieren"
        case .it: return "Esporta rapporto MHL"
        }
    }

    // MARK: - Stats
    var statFound: String {
        switch language {
        case .fr: return "Trouvés"
        case .en: return "Found"
        case .es: return "Encontrados"
        case .de: return "Gefunden"
        case .it: return "Trovati"
        }
    }
    var statCopied: String {
        switch language {
        case .fr: return "Copiés"
        case .en: return "Copied"
        case .es: return "Copiados"
        case .de: return "Kopiert"
        case .it: return "Copiati"
        }
    }
    var statVerified: String {
        switch language {
        case .fr: return "Vérifiés"
        case .en: return "Verified"
        case .es: return "Verificados"
        case .de: return "Verifiziert"
        case .it: return "Verificati"
        }
    }
    var statFailed: String {
        switch language {
        case .fr: return "Erreurs"
        case .en: return "Errors"
        case .es: return "Errores"
        case .de: return "Fehler"
        case .it: return "Errori"
        }
    }

    // MARK: - Action button
    var actionInterrupt: String {
        switch language {
        case .fr: return "Interrompre la copie"
        case .en: return "Interrupt copy"
        case .es: return "Interrumpir la copia"
        case .de: return "Kopie unterbrechen"
        case .it: return "Interrompi copia"
        }
    }
    var actionInterruptRegistered: String {
        switch language {
        case .fr: return "Interruption enregistrée…"
        case .en: return "Interruption registered…"
        case .es: return "Interrupción registrada…"
        case .de: return "Unterbrechung registriert…"
        case .it: return "Interruzione registrata…"
        }
    }
    var interruptHint: String {
        switch language {
        case .fr: return "La progression est conservée en cas d'interruption — la copie reprendra où elle s'est arrêtée"
        case .en: return "Progress is preserved if you interrupt — the copy will resume where it stopped"
        case .es: return "El progreso se conserva si interrumpes — la copia continuará donde se detuvo"
        case .de: return "Der Fortschritt bleibt bei Unterbrechung erhalten — die Kopie wird dort fortgesetzt, wo sie gestoppt wurde"
        case .it: return "Il progresso viene conservato in caso di interruzione — la copia riprenderà da dove si è fermata"
        }
    }
    func actionRetryFailed(count: Int) -> String {
        switch language {
        case .fr: return "Recopier les fichiers en erreur (\(count))"
        case .en: return "Re-copy failed files (\(count))"
        case .es: return "Volver a copiar los archivos con error (\(count))"
        case .de: return "Fehlerhafte Dateien erneut kopieren (\(count))"
        case .it: return "Ri-copia file con errore (\(count))"
        }
    }
    var actionStartSim: String {
        switch language {
        case .fr: return "Lancer la simulation"
        case .en: return "Start simulation"
        case .es: return "Iniciar simulación"
        case .de: return "Simulation starten"
        case .it: return "Avvia simulazione"
        }
    }
    var actionStart: String {
        switch language {
        case .fr: return "Lancer la copie sécurisée"
        case .en: return "Start secure copy"
        case .es: return "Iniciar copia segura"
        case .de: return "Sichere Kopie starten"
        case .it: return "Avvia copia sicura"
        }
    }
    var actionStartVerify: String {
        switch language {
        case .fr: return "Lancer la vérification"
        case .en: return "Start verification"
        case .es: return "Iniciar verificación"
        case .de: return "Verifizierung starten"
        case .it: return "Avvia verifica"
        }
    }

    // MARK: - Journal empty
    var journalEmpty: String {
        switch language {
        case .fr: return "Aucune activité pour le moment"
        case .en: return "No activity yet"
        case .es: return "Sin actividad por ahora"
        case .de: return "Noch keine Aktivität"
        case .it: return "Nessuna attività al momento"
        }
    }

    // MARK: - Footer
    var footerCredit: String {
        switch language {
        case .fr: return "MisiCopy créé par Matthieu Misiraca"
        case .en: return "MisiCopy by Matthieu Misiraca"
        case .es: return "MisiCopy por Matthieu Misiraca"
        case .de: return "MisiCopy von Matthieu Misiraca"
        case .it: return "MisiCopy di Matthieu Misiraca"
        }
    }

    // MARK: - Engine logs
    func logSourceSelected(_ name: String) -> String {
        switch language {
        case .fr: return "Source sélectionnée — \(name)"
        case .en: return "Source selected — \(name)"
        case .es: return "Origen seleccionado — \(name)"
        case .de: return "Quelle ausgewählt — \(name)"
        case .it: return "Sorgente selezionata — \(name)"
        }
    }
    func logDestAdded(_ name: String) -> String {
        switch language {
        case .fr: return "Destination ajoutée — \(name)"
        case .en: return "Destination added — \(name)"
        case .es: return "Destino añadido — \(name)"
        case .de: return "Ziel hinzugefügt — \(name)"
        case .it: return "Destinazione aggiunta — \(name)"
        }
    }
    var logCancelRequested: String {
        switch language {
        case .fr: return "Annulation demandée"
        case .en: return "Cancellation requested"
        case .es: return "Cancelación solicitada"
        case .de: return "Abbruch angefordert"
        case .it: return "Annullamento richiesto"
        }
    }
    var logNoSource: String {
        switch language {
        case .fr: return "Aucune source sélectionnée"
        case .en: return "No source selected"
        case .es: return "Ningún origen seleccionado"
        case .de: return "Keine Quelle ausgewählt"
        case .it: return "Nessuna sorgente selezionata"
        }
    }
    var logNoDestination: String {
        switch language {
        case .fr: return "Aucune destination sélectionnée"
        case .en: return "No destination selected"
        case .es: return "Ningún destino seleccionado"
        case .de: return "Kein Ziel ausgewählt"
        case .it: return "Nessuna destinazione selezionata"
        }
    }
    var logIndexing: String {
        switch language {
        case .fr: return "Indexation des fichiers…"
        case .en: return "Indexing files…"
        case .es: return "Indexando archivos…"
        case .de: return "Dateien indizieren…"
        case .it: return "Indicizzazione file…"
        }
    }
    var settingsAlgorithmSection: String {
        switch language {
        case .fr: return "Algorithme de checksum"
        case .en: return "Checksum algorithm"
        case .es: return "Algoritmo de checksum"
        case .de: return "Prüfsummen-Algorithmus"
        case .it: return "Algoritmo checksum"
        }
    }
    var settingsAlgorithmFooter: String {
        switch language {
        case .fr: return "xxHash3 (64-bit) est recommandé : c'est le plus rapide sur Apple Silicon et le standard de l'industrie pour détecter la corruption accidentelle. SHA-256 est un algorithme cryptographique : il ne détecte pas mieux les erreurs de copie mais est 8 à 10 fois plus lent — réservez-le aux livraisons qui l'exigent contractuellement."
        case .en: return "xxHash3 (64-bit) is recommended: the fastest on Apple Silicon and the industry standard for detecting accidental corruption. SHA-256 is a cryptographic algorithm: it detects copy errors no better but runs 8–10× slower — reserve it for deliveries that contractually require it."
        case .es: return "xxHash3 (64-bit) es el recomendado: el más rápido en Apple Silicon y el estándar de la industria para detectar corrupción accidental. SHA-256 es un algoritmo criptográfico: no detecta mejor los errores de copia pero es 8–10 veces más lento — resérvalo para entregas que lo exijan contractualmente."
        case .de: return "xxHash3 (64-bit) wird empfohlen: am schnellsten auf Apple Silicon und Industriestandard zur Erkennung zufälliger Beschädigungen. SHA-256 ist ein kryptografischer Algorithmus: Er erkennt Kopierfehler nicht besser, ist aber 8–10× langsamer — reservieren Sie ihn für Lieferungen, die ihn vertraglich erfordern."
        case .it: return "xxHash3 (64-bit) è raccomandato: il più veloce su Apple Silicon e lo standard del settore per rilevare la corruzione accidentale. SHA-256 è un algoritmo crittografico: non rileva gli errori di copia meglio ma è 8–10× più lento — riservalo alle consegne che lo richiedono contrattualmente."
        }
    }
    func logCascadeEnabled(_ name: String) -> String {
        switch language {
        case .fr: return "« \(name) » passe en cascade — alimentée depuis la première destination après la copie principale"
        case .en: return "\"\(name)\" switched to cascade — fed from the first destination after the primary copy"
        case .es: return "« \(name) » pasa a cascada — alimentada desde el primer destino tras la copia principal"
        case .de: return "\"\(name)\" switched to cascade — fed from the first destination after the primary copy"
        case .it: return "\"\(name)\" switched to cascade — fed from the first destination after the primary copy"
        }
    }
    func logCascadeDisabled(_ name: String) -> String {
        switch language {
        case .fr: return "« \(name) » repasse en destination directe"
        case .en: return "\"\(name)\" switched back to a direct destination"
        case .es: return "« \(name) » vuelve a destino directo"
        case .de: return "\"\(name)\" switched back to a direct destination"
        case .it: return "\"\(name)\" switched back to a direct destination"
        }
    }
    var logSourcesFreed: String {
        switch language {
        case .fr: return "✅ Copie principale vérifiée — les cartes sources sont libérées, la cascade prend le relais"
        case .en: return "✅ Primary copy verified — source cards are released, the cascade takes over"
        case .es: return "✅ Copia principal verificada — las tarjetas origen quedan libres, la cascada toma el relevo"
        case .de: return "✅ Primärkopie verifiziert — Quellkarten freigegeben, Kaskade übernimmt"
        case .it: return "✅ Copia principale verificata — schede sorgente liberate, la cascata subentra"
        }
    }
    func logCascadeStart(feed: String, count: Int) -> String {
        switch language {
        case .fr: return "Cascade : alimentation de \(count) destination(s) depuis « \(feed) »…"
        case .en: return "Cascade: feeding \(count) destination(s) from \"\(feed)\"…"
        case .es: return "Cascada: alimentando \(count) destino(s) desde « \(feed) »…"
        case .de: return "Cascade: feeding \(count) destination(s) from \"\(feed)\"…"
        case .it: return "Cascade: feeding \(count) destination(s) from \"\(feed)\"…"
        }
    }
    func logCascadeDone(count: Int) -> String {
        switch language {
        case .fr: return "Cascade terminée — \(count) destination(s) alimentée(s)"
        case .en: return "Cascade finished — \(count) destination(s) fed"
        case .es: return "Cascada terminada — \(count) destino(s) alimentado(s)"
        case .de: return "Cascade finished — \(count) destination(s) fed"
        case .it: return "Cascade finished — \(count) destination(s) fed"
        }
    }
    func logCascadeFeedMismatch(_ name: String) -> String {
        switch language {
        case .fr: return "cascade : le fichier relu sur « \(name) » ne correspond plus à la source"
        case .en: return "cascade: the file re-read from \"\(name)\" no longer matches the source"
        case .es: return "cascada: el archivo releído de « \(name) » ya no coincide con el origen"
        case .de: return "cascade: the file re-read from \"\(name)\" no longer matches the source"
        case .it: return "cascade: the file re-read from \"\(name)\" no longer matches the source"
        }
    }
    var logCascadeAllFallback: String {
        switch language {
        case .fr: return "Toutes les destinations sont en cascade — il faut au moins une destination directe pour les alimenter. Les drapeaux cascade sont ignorés pour cette copie."
        case .en: return "All destinations are set to cascade — at least one direct destination is needed to feed them. Cascade flags are ignored for this copy."
        case .es: return "Todos los destinos están en cascada — se necesita al menos un destino directo para alimentarlos. Las marcas de cascada se ignoran en esta copia."
        case .de: return "Alle Ziele sind als Kaskade eingestellt — mindestens ein direktes Ziel wird benötigt. Kaskaden-Flags werden für diese Kopie ignoriert."
        case .it: return "Tutte le destinazioni sono in cascata — è necessaria almeno una destinazione diretta. I flag cascata vengono ignorati per questa copia."
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
        case .de: formatter.locale = Locale(identifier: "de_DE")
        case .it: formatter.locale = Locale(identifier: "it_IT")
        }
        return formatter.string(from: date)
    }
    var remotePhaseCascade: String {
        switch language {
        case .fr: return "Cascade — cartes libérées ✅"
        case .en: return "Cascade — cards released ✅"
        case .es: return "Cascada — tarjetas liberadas ✅"
        case .de: return "Kaskade — Karten freigegeben ✅"
        case .it: return "Cascata — schede rilasciate ✅"
        }
    }
    func logKnownCardDetected(_ name: String, when: String) -> String {
        switch language {
        case .fr: return "Carte « \(name) » reconnue — déjà déchargée le \(when)"
        case .en: return "Card \"\(name)\" recognized — already offloaded on \(when)"
        case .es: return "Tarjeta « \(name) » reconocida — ya descargada el \(when)"
        case .de: return "Card \"\(name)\" recognized — already offloaded on \(when)"
        case .it: return "Card \"\(name)\" recognized — already offloaded on \(when)"
        }
    }
    func cardAlreadyOffloaded(_ name: String, when: String, files: Int, volume: String) -> String {
        switch language {
        case .fr: return "« \(name) » déjà déchargée le \(when) — \(files) fichier(s), \(volume)"
        case .en: return "\"\(name)\" already offloaded on \(when) — \(files) file(s), \(volume)"
        case .es: return "« \(name) » ya descargada el \(when) — \(files) archivo(s), \(volume)"
        case .de: return "\"\(name)\" already offloaded on \(when) — \(files) file(s), \(volume)"
        case .it: return "\"\(name)\" already offloaded on \(when) — \(files) file(s), \(volume)"
        }
    }
    var buttonReverify: String {
        switch language {
        case .fr: return "Re-vérifier"
        case .en: return "Re-verify"
        case .es: return "Re-verificar"
        case .de: return "Erneut verifizieren"
        case .it: return "Ri-verifica"
        }
    }
    var buttonRecopy: String {
        switch language {
        case .fr: return "Recopier"
        case .en: return "Re-copy"
        case .es: return "Recopiar"
        case .de: return "Erneut kopieren"
        case .it: return "Ri-copia"
        }
    }
    func logPreflightSpace(_ name: String, missing: String) -> String {
        switch language {
        case .fr: return "⛔️ Copie refusée : espace insuffisant sur « \(name) » — il manque \(missing)"
        case .en: return "⛔️ Copy refused: not enough space on \"\(name)\" — \(missing) missing"
        case .es: return "⛔️ Copia rechazada: espacio insuficiente en « \(name) » — faltan \(missing)"
        case .de: return "⛔️ Copy refused: not enough space on \"\(name)\" — \(missing) missing"
        case .it: return "⛔️ Copy refused: not enough space on \"\(name)\" — \(missing) missing"
        }
    }
    var preflightAlertTitle: String {
        switch language {
        case .fr: return "Espace insuffisant"
        case .en: return "Not enough space"
        case .es: return "Espacio insuficiente"
        case .de: return "Nicht genug Speicherplatz"
        case .it: return "Spazio insufficiente"
        }
    }
    func preflightAlertMessage(name: String, needed: String, free: String, missing: String) -> String {
        switch language {
        case .fr: return "La copie nécessite \(needed) mais « \(name) » n'a que \(free) de libre (il manque \(missing)).\n\nLibérez de l'espace ou choisissez une autre destination — rien n'a été copié."
        case .en: return "The copy needs \(needed) but \"\(name)\" only has \(free) free (\(missing) missing).\n\nFree up space or pick another destination — nothing was copied."
        case .es: return "La copia necesita \(needed) pero « \(name) » solo tiene \(free) libres (faltan \(missing)).\n\nLibera espacio o elige otro destino — no se copió nada."
        case .de: return "Die Kopie benötigt \(needed), aber \"\(name)\" hat nur \(free) frei (\(missing) fehlen).\n\nGeben Sie Speicherplatz frei oder wählen Sie ein anderes Ziel — es wurde nichts kopiert."
        case .it: return "La copia richiede \(needed) ma \"\(name)\" ha solo \(free) liberi (\(missing) mancanti).\n\nLibera spazio o scegli un'altra destinazione — non è stato copiato nulla."
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
        case .de:
            let err = errors == 0 ? "0 Fehler" : "\(errors) Fehler"
            return "Heute: \(cards) Karte(n) · \(volume) · \(err)"
        case .it:
            let err = errors == 0 ? "0 errori" : "\(errors) errore/i"
            return "Oggi: \(cards) scheda/e · \(volume) · \(err)"
        }
    }
    func logDestSpeedMeasured(_ name: String, mbs: Double) -> String {
        let v = Int(mbs.rounded())
        switch language {
        case .fr: return "Vitesse mesurée sur « \(name) » : écriture ≈ \(v) Mo/s"
        case .en: return "Measured speed on \"\(name)\": write ≈ \(v) MB/s"
        case .es: return "Velocidad medida en « \(name) »: escritura ≈ \(v) MB/s"
        case .de: return "Gemessene Geschwindigkeit auf \"\(name)\": Schreiben ≈ \(v) MB/s"
        case .it: return "Velocità misurata su \"\(name)\": scrittura ≈ \(v) MB/s"
        }
    }
    var unitMBs: String {
        switch language {
        case .fr: return "Mo/s"
        case .en: return "MB/s"
        case .es: return "MB/s"
        case .de: return "MB/s"
        case .it: return "MB/s"
        }
    }
    var tooltipFastestDrive: String {
        switch language {
        case .fr: return "Le disque le plus rapide — idéal en destination directe"
        case .en: return "The fastest drive — ideal as a direct destination"
        case .es: return "El disco más rápido — ideal como destino directo"
        case .de: return "Das schnellste Laufwerk — ideal als direktes Ziel"
        case .it: return "Il disco più veloce — ideale come destinazione diretta"
        }
    }
    var tooltipSpeedBadge: String {
        switch language {
        case .fr: return "Vitesse d'écriture mesurée — cliquez pour re-mesurer"
        case .en: return "Measured write speed — click to re-measure"
        case .es: return "Velocidad de escritura medida — haz clic para volver a medir"
        case .de: return "Gemessene Schreibgeschwindigkeit — klicken zum Neuberechnen"
        case .it: return "Velocità di scrittura misurata — fai clic per ri-misurare"
        }
    }
    var tooltipSlowDrive: String {
        switch language {
        case .fr: return "Disque le plus lent — bon candidat pour la cascade (bouton ↳)"
        case .en: return "Slowest drive — a good cascade candidate (↳ button)"
        case .es: return "Disco más lento — buen candidato para la cascada (botón ↳)"
        case .de: return "Langsamstes Laufwerk — guter Kaskadenkandidat (↳ Taste)"
        case .it: return "Disco più lento — buon candidato per la cascata (pulsante ↳)"
        }
    }
    func completionDialogMessage(verifyOnly: Bool, verified: Int, failed: Int,
                                 bytes: String, duration: String) -> String {
        let action: String
        switch language {
        case .fr: action = verifyOnly ? "vérifiés" : "copiés et vérifiés"
        case .en: action = verifyOnly ? "verified" : "copied and verified"
        case .es: action = verifyOnly ? "verificados" : "copiados y verificados"
        case .de: action = verifyOnly ? "verifiziert" : "kopiert und verifiziert"
        case .it: action = verifyOnly ? "verificati" : "copiati e verificati"
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
        case .de:
            return failed == 0
                ? "\(verified) Datei(en) \(action) — \(bytes) in \(duration)."
                : "\(verified) Datei(en) verifiziert, \(failed) fehlgeschlagen — \(bytes) in \(duration).\n\"Fehlerhafte Dateien erneut kopieren\" verwenden, um es erneut zu versuchen."
        case .it:
            return failed == 0
                ? "\(verified) file \(action) — \(bytes) in \(duration)."
                : "\(verified) file verificati, \(failed) con errore — \(bytes) in \(duration).\nUsa \"Ri-copia file con errore\" per riprovare."
        }
    }
    var settingsCompletionDialogToggle: String {
        switch language {
        case .fr: return "Boîte de dialogue en fin de copie"
        case .en: return "Dialog box when a copy finishes"
        case .es: return "Cuadro de diálogo al terminar la copia"
        case .de: return "Dialogfeld bei Kopierende"
        case .it: return "Finestra di dialogo al termine della copia"
        }
    }
    var cascadeAlertTitle: String {
        switch language {
        case .fr: return "Impossible de tout passer en cascade"
        case .en: return "Can't set everything to cascade"
        case .es: return "No se puede poner todo en cascada"
        case .de: return "Nicht alles auf Kaskade setzen möglich"
        case .it: return "Impossibile impostare tutto in cascata"
        }
    }
    var cascadeAlertMessage: String {
        switch language {
        case .fr: return "Une cascade est alimentée depuis la première destination directe. Il faut donc conserver au moins une destination directe (idéalement le disque le plus rapide ⚡) — les cascades seront copiées depuis elle une fois la copie principale vérifiée."
        case .en: return "A cascade is fed from the first direct destination. Keep at least one direct destination (ideally the fastest drive ⚡) — the cascades will be copied from it once the primary copy is verified."
        case .es: return "Una cascada se alimenta desde el primer destino directo. Conserva al menos un destino directo (idealmente el disco más rápido ⚡) — las cascadas se copiarán desde él una vez verificada la copia principal."
        case .de: return "Eine Kaskade wird vom ersten direkten Ziel gespeist. Behalten Sie mindestens ein direktes Ziel (idealerweise das schnellste Laufwerk ⚡) — Kaskaden werden daraus kopiert, sobald die Primärkopie verifiziert ist."
        case .it: return "Una cascata è alimentata dalla prima destinazione diretta. Mantieni almeno una destinazione diretta (idealmente il disco più veloce ⚡) — le cascate verranno copiate da essa una volta verificata la copia principale."
        }
    }
    var tooltipCascade: String {
        switch language {
        case .fr: return "Cascade : cette destination sera alimentée depuis la première destination une fois la copie principale vérifiée — la carte est libérée plus tôt"
        case .en: return "Cascade: this destination is fed from the first destination once the primary copy is verified — the card is released earlier"
        case .es: return "Cascada: este destino se alimenta desde el primer destino una vez verificada la copia principal — la tarjeta queda libre antes"
        case .de: return "Kaskade: Dieses Ziel wird vom ersten Ziel gespeist, sobald die Primärkopie verifiziert ist — die Karte wird früher freigegeben"
        case .it: return "Cascata: questa destinazione è alimentata dalla prima una volta verificata la copia principale — la scheda viene rilasciata prima"
        }
    }
    var logVerifyNoReportWritten: String {
        switch language {
        case .fr: return "Vérification seule : aucun fichier écrit sur les destinations — exportez le rapport via Fichier → Exporter si besoin"
        case .en: return "Verify only: nothing written to the destinations — export the report via File → Export if needed"
        case .es: return "Solo verificación: no se escribe nada en los destinos — exporta el informe vía Archivo → Exportar si lo necesitas"
        case .de: return "Nur verifizieren: nichts wird auf die Ziele geschrieben — Bericht bei Bedarf über Datei → Exportieren"
        case .it: return "Solo verifica: niente viene scritto nelle destinazioni — esporta il rapporto via File → Esporta se necessario"
        }
    }
    var logWatchAutoStartSkippedVerify: String {
        switch language {
        case .fr: return "Auto-start ignoré : le mode « Vérification seule » est actif — passez en mode copie pour décharger cette carte"
        case .en: return "Auto-start skipped: 'Verify only' mode is active — switch to a copy mode to offload this card"
        case .es: return "Auto-inicio omitido: el modo « Solo verificación » está activo — cambia a un modo de copia para descargar esta tarjeta"
        case .de: return "Auto-Start übersprungen: Modus 'Nur verifizieren' aktiv — Kopiermodus wählen"
        case .it: return "Auto-avvio saltato: modalità 'Solo verifica' attiva — passa a una modalità di copia per scaricare la scheda"
        }
    }
    func logResumeSkipped(count: Int) -> String {
        switch language {
        case .fr: return "⏩ \(count) fichier(s) déjà sécurisé(s) — ignorés (reprise)"
        case .en: return "⏩ \(count) file(s) already secured — skipped (resume)"
        case .es: return "⏩ \(count) archivo(s) ya asegurado(s) — omitidos (reanudación)"
        case .de: return "⏩ \(count) Datei(en) bereits gesichert — übersprungen (Wiederaufnahme)"
        case .it: return "⏩ \(count) file già salvato/i — saltati (ripresa)"
        }
    }
    func logResumeSaved(count: Int) -> String {
        switch language {
        case .fr: return "Progression sauvegardée (\(count) fichier(s)) — la prochaine copie reprendra où elle s'est arrêtée"
        case .en: return "Progress saved (\(count) file(s)) — the next copy will resume where it stopped"
        case .es: return "Progreso guardado (\(count) archivo(s)) — la próxima copia continuará donde se detuvo"
        case .de: return "Fortschritt gespeichert (\(count) Datei(en)) — die nächste Kopie wird dort fortgesetzt, wo sie gestoppt wurde"
        case .it: return "Progresso salvato (\(count) file) — la prossima copia riprenderà da dove si è fermata"
        }
    }
    func logParallelSources(count: Int) -> String {
        switch language {
        case .fr: return "Copie parallèle : \(count) sources traitées simultanément"
        case .en: return "Parallel copy: \(count) sources processed simultaneously"
        case .es: return "Copia paralela: \(count) orígenes procesados simultáneamente"
        case .de: return "Parallele Kopie: \(count) Quellen werden gleichzeitig verarbeitet"
        case .it: return "Copia parallela: \(count) sorgenti elaborate simultaneamente"
        }
    }
    func logRetryFailedStart(count: Int) -> String {
        switch language {
        case .fr: return "Relance des \(count) fichier(s) en erreur uniquement…"
        case .en: return "Re-running on the \(count) failed file(s) only…"
        case .es: return "Reintentando solo los \(count) archivo(s) con error…"
        case .de: return "Nur die \(count) fehlerhaften Datei(en) werden erneut versucht…"
        case .it: return "Riprovando solo i \(count) file con errore…"
        }
    }
    func logRetryFailedIndexing(count: Int) -> String {
        switch language {
        case .fr: return "\(count) fichier(s) à reprendre — copie ciblée"
        case .en: return "\(count) file(s) to retry — targeted copy"
        case .es: return "\(count) archivo(s) a reintentar — copia dirigida"
        case .de: return "\(count) Datei(en) erneut versuchen — gezielte Kopie"
        case .it: return "\(count) file da riprovare — copia mirata"
        }
    }
    var errMissingSourceChecksum: String {
        switch language {
        case .fr: return "empreinte source manquante"
        case .en: return "missing source checksum"
        case .es: return "falta la suma de comprobación origen"
        case .de: return "fehlende Quell-Prüfsumme"
        case .it: return "checksum sorgente mancante"
        }
    }
    var pdfPreviewUnavailable: String {
        switch language {
        case .fr: return "Aperçu indisponible"
        case .en: return "Preview unavailable"
        case .es: return "Vista previa no disponible"
        case .de: return "Vorschau nicht verfügbar"
        case .it: return "Anteprima non disponibile"
        }
    }
    func logFilesFound(count: Int, bytes: String) -> String {
        switch language {
        case .fr: return "\(count) fichier(s) trouvé(s) — \(bytes)"
        case .en: return "\(count) file(s) found — \(bytes)"
        case .es: return "\(count) archivo(s) encontrado(s) — \(bytes)"
        case .de: return "\(count) Datei(en) gefunden — \(bytes)"
        case .it: return "\(count) file trovato/i — \(bytes)"
        }
    }
    var logSimulation: String {
        switch language {
        case .fr: return "Mode simulation — aucun fichier ne sera copié"
        case .en: return "Simulation mode — no file will be copied"
        case .es: return "Modo simulación — no se copiará ningún archivo"
        case .de: return "Simulationsmodus — keine Datei wird kopiert"
        case .it: return "Modalità simulazione — nessun file verrà copiato"
        }
    }
    var logCancelled: String {
        switch language {
        case .fr: return "Opération annulée"
        case .en: return "Operation cancelled"
        case .es: return "Operación cancelada"
        case .de: return "Vorgang abgebrochen"
        case .it: return "Operazione annullata"
        }
    }
    var cancelCleanupTitle: String {
        switch language {
        case .fr: return "Copie interrompue"
        case .en: return "Copy interrupted"
        case .es: return "Copia interrumpida"
        case .de: return "Kopie unterbrochen"
        case .it: return "Copia interrotta"
        }
    }
    func cancelCleanupMessage(count: Int) -> String {
        switch language {
        case .fr: return "\(count) fichier(s) ont été copiés avant l'interruption. Supprimer ces copies pour libérer l'espace, ou les conserver pour reprendre où vous vous étiez arrêté ?"
        case .en: return "\(count) file(s) were copied before the interruption. Delete them to free up space, or keep them to resume where you left off?"
        case .es: return "\(count) archivo(s) se copiaron antes de la interrupción. ¿Eliminarlos para liberar espacio o conservarlos para reanudar?"
        case .de: return "\(count) Datei(en) wurden vor der Unterbrechung kopiert. Löschen, um Speicherplatz freizugeben, oder behalten, um dort fortzufahren, wo Sie aufgehört haben?"
        case .it: return "\(count) file sono stati copiati prima dell'interruzione. Eliminarli per liberare spazio o conservarli per riprendere da dove ci si era fermati?"
        }
    }
    func cancelCleanupDelete(count: Int) -> String {
        switch language {
        case .fr: return "Supprimer (\(count) fichier(s))"
        case .en: return "Delete (\(count) file(s))"
        case .es: return "Eliminar (\(count) archivo(s))"
        case .de: return "Löschen (\(count) Datei(en))"
        case .it: return "Elimina (\(count) file)"
        }
    }
    var cancelCleanupKeep: String {
        switch language {
        case .fr: return "Conserver et reprendre"
        case .en: return "Keep and resume"
        case .es: return "Conservar y reanudar"
        case .de: return "Behalten und fortsetzen"
        case .it: return "Mantieni e riprendi"
        }
    }
    func logCancelCleanupDone(count: Int) -> String {
        switch language {
        case .fr: return "Copies partielles supprimées — \(count) fichier(s) effacé(s)"
        case .en: return "Partial copies deleted — \(count) file(s) removed"
        case .es: return "Copias parciales eliminadas — \(count) archivo(s) borrado(s)"
        case .de: return "Teilkopien gelöscht — \(count) Datei(en) entfernt"
        case .it: return "Copie parziali eliminate — \(count) file rimosso/i"
        }
    }
    func logDone(verified: Int, found: Int) -> String {
        switch language {
        case .fr: return "Terminé — \(verified)/\(found) vérifié(s)"
        case .en: return "Done — \(verified)/\(found) verified"
        case .es: return "Listo — \(verified)/\(found) verificados"
        case .de: return "Fertig — \(verified)/\(found) verifiziert"
        case .it: return "Fatto — \(verified)/\(found) verificato/i"
        }
    }
    func logDoneWithErrors(_ failed: Int) -> String {
        switch language {
        case .fr: return "Terminé avec \(failed) erreur(s)"
        case .en: return "Done with \(failed) error(s)"
        case .es: return "Terminado con \(failed) error(es)"
        case .de: return "Abgeschlossen mit \(failed) Fehler(n)"
        case .it: return "Completato con \(failed) errore/i"
        }
    }
    var flashSuccessTitle: String {
        switch language {
        case .fr: return "Copie réussie"
        case .en: return "Copy succeeded"
        case .es: return "Copia exitosa"
        case .de: return "Kopie erfolgreich"
        case .it: return "Copia riuscita"
        }
    }
    func flashSuccessSubtitle(verified: Int, bytes: String) -> String {
        switch language {
        case .fr: return "\(verified) fichier(s) vérifié(s) — \(bytes)"
        case .en: return "\(verified) file(s) verified — \(bytes)"
        case .es: return "\(verified) archivo(s) verificado(s) — \(bytes)"
        case .de: return "\(verified) Datei(en) verifiziert — \(bytes)"
        case .it: return "\(verified) file verificato/i — \(bytes)"
        }
    }
    var flashFailureTitle: String {
        switch language {
        case .fr: return "Copie terminée avec erreurs"
        case .en: return "Copy finished with errors"
        case .es: return "Copia terminada con errores"
        case .de: return "Kopie mit Fehlern abgeschlossen"
        case .it: return "Copia terminata con errori"
        }
    }
    func flashFailureSubtitle(failed: Int) -> String {
        switch language {
        case .fr: return "\(failed) fichier(s) en erreur — voir le journal"
        case .en: return "\(failed) file(s) failed — check the activity log"
        case .es: return "\(failed) archivo(s) con error — revisa el registro"
        case .de: return "\(failed) Datei(en) fehlgeschlagen — Aktivitätsprotokoll prüfen"
        case .it: return "\(failed) file con errore — controlla il registro attività"
        }
    }
    var flashCancelledTitle: String {
        switch language {
        case .fr: return "Copie annulée"
        case .en: return "Copy cancelled"
        case .es: return "Copia cancelada"
        case .de: return "Kopie abgebrochen"
        case .it: return "Copia annullata"
        }
    }
    var flashCancelledSubtitle: String {
        switch language {
        case .fr: return "Aucun REEL n'a été engagé"
        case .en: return "No REEL has been committed"
        case .es: return "No se ha registrado ningún REEL"
        case .de: return "Kein REEL wurde festgeschrieben"
        case .it: return "Nessun REEL è stato confermato"
        }
    }
    func logFileOK(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — OK"
        case .en: return "\(name) — OK"
        case .es: return "\(name) — OK"
        case .de: return "\(name) — OK"
        case .it: return "\(name) — OK"
        }
    }
    func logDoubleVerifyPass(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — source re-vérifiée (stable)"
        case .en: return "\(name) — source re-verified (stable)"
        case .es: return "\(name) — origen re-verificado (estable)"
        case .de: return "\(name) — Quelle re-verifiziert (stabil)"
        case .it: return "\(name) — sorgente ri-verificata (stabile)"
        }
    }
    func logSourceReadError(_ message: String) -> String {
        switch language {
        case .fr: return "lecture source — \(message)"
        case .en: return "source read — \(message)"
        case .es: return "lectura origen — \(message)"
        case .de: return "Quelllesen — \(message)"
        case .it: return "lettura sorgente — \(message)"
        }
    }
    func logCopyError(destination: String, message: String) -> String {
        switch language {
        case .fr: return "copie vers \(destination) — \(message)"
        case .en: return "copy to \(destination) — \(message)"
        case .es: return "copia hacia \(destination) — \(message)"
        case .de: return "Kopie nach \(destination) — \(message)"
        case .it: return "copia in \(destination) — \(message)"
        }
    }
    func logChecksumMismatch(_ destination: String) -> String {
        switch language {
        case .fr: return "checksum différent (\(destination))"
        case .en: return "checksum mismatch (\(destination))"
        case .es: return "checksum distinto (\(destination))"
        case .de: return "Prüfsumme stimmt nicht überein (\(destination))"
        case .it: return "checksum non corrisponde (\(destination))"
        }
    }
    var logSourceUnstable: String {
        switch language {
        case .fr: return "source instable"
        case .en: return "unstable source"
        case .es: return "origen inestable"
        case .de: return "instabile Quelle"
        case .it: return "sorgente instabile"
        }
    }
    func logVerifyError(_ message: String) -> String {
        switch language {
        case .fr: return "vérif destination — \(message)"
        case .en: return "destination verification — \(message)"
        case .es: return "verificación destino — \(message)"
        case .de: return "Zielverifizierung — \(message)"
        case .it: return "verifica destinazione — \(message)"
        }
    }
    var exportUnavailable: String {
        switch language {
        case .fr: return "Export indisponible pendant la copie"
        case .en: return "Export unavailable during copy"
        case .es: return "Exportación no disponible durante la copia"
        case .de: return "Export während Kopie nicht verfügbar"
        case .it: return "Esportazione non disponibile durante la copia"
        }
    }
    var exportEncodeFailed: String {
        switch language {
        case .fr: return "Encodage du rapport impossible"
        case .en: return "Cannot encode report"
        case .es: return "No se puede codificar el informe"
        case .de: return "Bericht kann nicht kodiert werden"
        case .it: return "Impossibile codificare il rapporto"
        }
    }
    func exportFailed(_ message: String) -> String {
        switch language {
        case .fr: return "Export échoué — \(message)"
        case .en: return "Export failed — \(message)"
        case .es: return "Exportación fallida — \(message)"
        case .de: return "Exportfehler — \(message)"
        case .it: return "Errore di esportazione — \(message)"
        }
    }
    func exportSucceeded(_ name: String) -> String {
        switch language {
        case .fr: return "Rapport MHL exporté — \(name)"
        case .en: return "MHL report exported — \(name)"
        case .es: return "Informe MHL exportado — \(name)"
        case .de: return "MHL-Bericht exportiert — \(name)"
        case .it: return "Rapporto MHL esportato — \(name)"
        }
    }
    func pdfReportWritten(_ name: String, in folder: String) -> String {
        switch language {
        case .fr: return "Rapport PDF écrit dans \(folder) — \(name)"
        case .en: return "PDF report written to \(folder) — \(name)"
        case .es: return "Informe PDF escrito en \(folder) — \(name)"
        case .de: return "PDF-Bericht geschrieben in \(folder) — \(name)"
        case .it: return "Rapporto PDF scritto in \(folder) — \(name)"
        }
    }
    func pdfReportFailed(_ folder: String) -> String {
        switch language {
        case .fr: return "Écriture du rapport PDF impossible dans \(folder)"
        case .en: return "Could not write PDF report to \(folder)"
        case .es: return "No se pudo escribir el informe PDF en \(folder)"
        case .de: return "PDF-Bericht konnte nicht in \(folder) geschrieben werden"
        case .it: return "Impossibile scrivere il rapporto PDF in \(folder)"
        }
    }
    func logEjected(_ name: String) -> String {
        switch language {
        case .fr: return "Volume éjecté — \(name)"
        case .en: return "Volume ejected — \(name)"
        case .es: return "Volumen expulsado — \(name)"
        case .de: return "Volume ausgeworfen — \(name)"
        case .it: return "Volume espulso — \(name)"
        }
    }
    func logEjectAttempt(_ name: String) -> String {
        switch language {
        case .fr: return "Tentative d'éjection — \(name)"
        case .en: return "Eject attempt — \(name)"
        case .es: return "Intento de expulsión — \(name)"
        case .de: return "Auswurfversuch — \(name)"
        case .it: return "Tentativo di espulsione — \(name)"
        }
    }
    // MARK: - Menu bar (localized)

    var menuFile: String {
        switch language {
        case .fr: return "Fichier"
        case .en: return "File"
        case .es: return "Archivo"
        case .de: return "Datei"
        case .it: return "File"
        }
    }
    var menuJob: String {
        switch language {
        case .fr: return "Tâche"
        case .en: return "Job"
        case .es: return "Tarea"
        case .de: return "Auftrag"
        case .it: return "Lavoro"
        }
    }
    var menuOptions: String {
        switch language {
        case .fr: return "Options"
        case .en: return "Options"
        case .es: return "Opciones"
        case .de: return "Optionen"
        case .it: return "Opzioni"
        }
    }
    var menuPresetsTitle: String {
        switch language {
        case .fr: return "Profils"
        case .en: return "Presets"
        case .es: return "Perfiles"
        case .de: return "Vorlagen"
        case .it: return "Preset"
        }
    }
    var menuLanguageTitle: String {
        switch language {
        case .fr: return "Langue"
        case .en: return "Language"
        case .es: return "Idioma"
        case .de: return "Sprache"
        case .it: return "Lingua"
        }
    }
    var menuCheckForUpdates: String {
        switch language {
        case .fr: return "Vérifier les mises à jour…"
        case .en: return "Check for Updates…"
        case .es: return "Buscar actualizaciones…"
        case .de: return "Nach Updates suchen…"
        case .it: return "Cerca aggiornamenti…"
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
        case .de: return "Einstellungen…"
        case .it: return "Impostazioni…"
        }
    }
    var menuDonate: String {
        switch language {
        case .fr: return "Acheter MisiCopy…"
        case .en: return "Buy MisiCopy…"
        case .es: return "Comprar MisiCopy…"
        case .de: return "MisiCopy kaufen…"
        case .it: return "Acquista MisiCopy…"
        }
    }
    var donateButton: String {
        switch language {
        case .fr: return "Acheter MisiCopy"
        case .en: return "Buy MisiCopy"
        case .es: return "Comprar MisiCopy"
        case .de: return "MisiCopy kaufen"
        case .it: return "Acquista MisiCopy"
        }
    }
    var donateBadge: String {
        switch language {
        case .fr: return "DONATEUR"
        case .en: return "DONOR"
        case .es: return "DONANTE"
        case .de: return "SPENDER"
        case .it: return "DONATORE"
        }
    }
    var donateQuitTitle: String {
        switch language {
        case .fr: return "Essai expiré"
        case .en: return "Trial expired"
        case .es: return "Prueba expirada"
        case .de: return "Testversion abgelaufen"
        case .it: return "Versione di prova scaduta"
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
        case .de:
            return "Ihr \(LicenseConfig.trialDays)-tägiger Test ist beendet. Kaufen Sie MisiCopy, um es ohne Einschränkungen weiterzuverwenden — einmaliger Kauf, Updates inklusive."
        case .it:
            return "Il tuo periodo di prova di \(LicenseConfig.trialDays) giorni è terminato. Acquista MisiCopy per continuare a usarlo senza limiti — un solo acquisto, aggiornamenti inclusi."
        }
    }
    var donateQuitContinue: String {
        switch language {
        case .fr: return "Plus tard"
        case .en: return "Later"
        case .es: return "Más tarde"
        case .de: return "Später"
        case .it: return "Più tardi"
        }
    }
    var licenseStateFree: String {
        switch language {
        case .fr: return "Version gratuite"
        case .en: return "Free version"
        case .es: return "Versión gratuita"
        case .de: return "Kostenlose Version"
        case .it: return "Versione gratuita"
        }
    }
    var licenseStateFreeHint: String {
        switch language {
        case .fr: return "Saisissez votre clé reçue après un don pour masquer le rappel à la fermeture"
        case .en: return "Enter the key you received after donating to hide the quit reminder"
        case .es: return "Introduce tu clave recibida tras donar para ocultar el recordatorio al salir"
        case .de: return "Geben Sie den nach dem Kauf erhaltenen Schlüssel ein, um den Erinnerungshinweis auszublenden"
        case .it: return "Inserisci la chiave ricevuta dopo l'acquisto per nascondere il promemoria"
        }
    }
    var emailFieldLabel: String {
        switch language {
        case .fr: return "Email (optionnel)"
        case .en: return "Email (optional)"
        case .es: return "Email (opcional)"
        case .de: return "E-Mail (optional)"
        case .it: return "Email (opzionale)"
        }
    }
    var emailFieldHint: String {
        switch language {
        case .fr: return "Pour affichage uniquement"
        case .en: return "Display only"
        case .es: return "Solo para visualización"
        case .de: return "Nur Anzeige"
        case .it: return "Solo visualizzazione"
        }
    }
    var bugReportButton: String {
        switch language {
        case .fr: return "BUG ?"
        case .en: return "BUG?"
        case .es: return "¿BUG?"
        case .de: return "FEHLER?"
        case .it: return "BUG?"
        }
    }
    var bugReportTooltip: String {
        switch language {
        case .fr: return "Signaler un bug par email à misicopy@misiraca.com"
        case .en: return "Report a bug by email to misicopy@misiraca.com"
        case .es: return "Reportar un bug por email a misicopy@misiraca.com"
        case .de: return "Fehler per E-Mail an misicopy@misiraca.com melden"
        case .it: return "Segnala un bug via email a misicopy@misiraca.com"
        }
    }

    // MARK: - Remote sync (iPhone)
    var remoteSectionLocal: String {
        switch language {
        case .fr: return "Réseau local (Wi-Fi)"
        case .en: return "Local network (Wi-Fi)"
        case .es: return "Red local (Wi-Fi)"
        case .de: return "Lokales Netzwerk (Wi-Fi)"
        case .it: return "Rete locale (Wi-Fi)"
        }
    }
    var remoteToggleEnable: String {
        switch language {
        case .fr: return "Activer le suivi depuis un iPhone"
        case .en: return "Allow iPhone live monitoring"
        case .es: return "Activar seguimiento desde iPhone"
        case .de: return "iPhone-Live-Überwachung erlauben"
        case .it: return "Consenti monitoraggio live iPhone"
        }
    }
    var remoteToggleFooter: String {
        switch language {
        case .fr: return "Permet à votre iPhone (sur le même Wi-Fi) de suivre la progression de la copie en temps réel et de la mettre en pause à distance. Aucune donnée ne quitte votre réseau."
        case .en: return "Lets your iPhone (on the same Wi-Fi) monitor copy progress live and pause it remotely. No data ever leaves your network."
        case .es: return "Permite a tu iPhone (en la misma red Wi-Fi) seguir el progreso de la copia en directo y pausarla remotamente. Ningún dato sale de tu red."
        case .de: return "Ermöglicht Ihrem iPhone (im selben WLAN), den Kopierfortschritt live zu überwachen und ihn per Fernzugriff zu pausieren. Es verlassen keine Daten Ihr Netzwerk."
        case .it: return "Permette al tuo iPhone (sulla stessa Wi-Fi) di monitorare in tempo reale il progresso della copia e di metterla in pausa a distanza. Nessun dato lascia la tua rete."
        }
    }
    var remoteSectionStatus: String {
        switch language {
        case .fr: return "État"
        case .en: return "Status"
        case .es: return "Estado"
        case .de: return "Status"
        case .it: return "Stato"
        }
    }
    var remoteStatusListening: String {
        switch language {
        case .fr: return "Service en écoute"
        case .en: return "Service listening"
        case .es: return "Servicio escuchando"
        case .de: return "Dienst aktiv"
        case .it: return "Servizio in ascolto"
        }
    }
    var remoteStatusStarting: String {
        switch language {
        case .fr: return "Démarrage…"
        case .en: return "Starting…"
        case .es: return "Iniciando…"
        case .de: return "Startet…"
        case .it: return "Avvio…"
        }
    }
    var remotePortLabel: String {
        switch language {
        case .fr: return "Port TCP"
        case .en: return "TCP port"
        case .es: return "Puerto TCP"
        case .de: return "TCP-Port"
        case .it: return "Porta TCP"
        }
    }
    var remoteClientsLabel: String {
        switch language {
        case .fr: return "iPhone connectés"
        case .en: return "Connected iPhones"
        case .es: return "iPhone conectados"
        case .de: return "Verbundene iPhones"
        case .it: return "iPhone connessi"
        }
    }
    var remoteSectionSecret: String {
        switch language {
        case .fr: return "Clé d'appairage"
        case .en: return "Pairing key"
        case .es: return "Clave de emparejamiento"
        case .de: return "Kopplungsschlüssel"
        case .it: return "Chiave di associazione"
        }
    }
    var remoteSecretLabel: String {
        switch language {
        case .fr: return "Secret partagé"
        case .en: return "Shared secret"
        case .es: return "Secreto compartido"
        case .de: return "Gemeinsames Geheimnis"
        case .it: return "Segreto condiviso"
        }
    }
    var remoteSecretFooter: String {
        switch language {
        case .fr: return "Ce secret sera codé dans le QR code d'appairage de l'app iPhone (à venir). Régénérez-le si vous suspectez qu'il a été compromis — tous les iPhones devront alors être ré-appairés."
        case .en: return "This secret will be embedded in the iPhone app pairing QR code (coming soon). Regenerate it if you think it was leaked — every paired iPhone will then need to pair again."
        case .es: return "Este secreto se incrustará en el código QR de emparejamiento de la app iPhone (próximamente). Regenéralo si crees que se filtró — todos los iPhone tendrán que volver a emparejarse."
        case .de: return "Dieses Geheimnis wird in den QR-Code der iPhone-Kopplung eingebettet (demnächst). Regenerieren Sie es, wenn Sie glauben, es wurde kompromittiert — jedes gekoppelte iPhone muss sich dann erneut koppeln."
        case .it: return "Questo segreto sarà incorporato nel QR code di abbinamento iPhone (prossimamente). Rigeneralo se pensi sia stato compromesso — ogni iPhone abbinato dovrà ri-abbinarsi."
        }
    }
    var remoteRegenerateSecret: String {
        switch language {
        case .fr: return "Régénérer le secret"
        case .en: return "Regenerate secret"
        case .es: return "Regenerar secreto"
        case .de: return "Geheimnis neu generieren"
        case .it: return "Rigenera segreto"
        }
    }
    var remoteSectionPairing: String {
        switch language {
        case .fr: return "Code d'appairage"
        case .en: return "Pairing code"
        case .es: return "Código de emparejamiento"
        case .de: return "Kopplungscode"
        case .it: return "Codice di abbinamento"
        }
    }
    var remotePairingFooter: String {
        switch language {
        case .fr: return "Scannez ce QR code depuis l'app iPhone MisiCopy Remote (à venir) pour autoriser votre téléphone à suivre les copies de ce Mac."
        case .en: return "Scan this QR code from the iPhone MisiCopy Remote app (coming soon) to authorize your phone to monitor copies from this Mac."
        case .es: return "Escanea este código QR desde la app iPhone MisiCopy Remote (próximamente) para autorizar a tu teléfono a seguir las copias de este Mac."
        case .de: return "Scannen Sie diesen QR-Code mit der iPhone MisiCopy Remote App (demnächst), um Ihr Telefon zu autorisieren, Kopien von diesem Mac zu überwachen."
        case .it: return "Scansiona questo QR code dall'app iPhone MisiCopy Remote (prossimamente) per autorizzare il tuo telefono a monitorare le copie da questo Mac."
        }
    }
    var remotePairingError: String {
        switch language {
        case .fr: return "Impossible de générer le QR code."
        case .en: return "Could not generate the QR code."
        case .es: return "No se pudo generar el código QR."
        case .de: return "QR-Code konnte nicht generiert werden."
        case .it: return "Impossibile generare il QR code."
        }
    }
    var remoteCopyPayload: String {
        switch language {
        case .fr: return "Copier le payload"
        case .en: return "Copy payload"
        case .es: return "Copiar payload"
        case .de: return "Payload kopieren"
        case .it: return "Copia payload"
        }
    }

    // MARK: - Settings tabs
    var settingsTabGeneral: String {
        switch language {
        case .fr: return "Général"
        case .en: return "General"
        case .es: return "General"
        case .de: return "Allgemein"
        case .it: return "Generale"
        }
    }
    var settingsTabRenaming: String {
        switch language {
        case .fr: return "Renommage"
        case .en: return "Renaming"
        case .es: return "Renombrado"
        case .de: return "Umbenennen"
        case .it: return "Rinomina"
        }
    }
    var settingsTabFilters: String {
        switch language {
        case .fr: return "Filtres"
        case .en: return "Filters"
        case .es: return "Filtros"
        case .de: return "Filter"
        case .it: return "Filtri"
        }
    }
    var settingsTabWatch: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        case .de: return "Überwachen"
        case .it: return "Sorveglia"
        }
    }
    var settingsTabIntegrations: String {
        switch language {
        case .fr: return "Intégrations"
        case .en: return "Integrations"
        case .es: return "Integraciones"
        case .de: return "Integrationen"
        case .it: return "Integrazioni"
        }
    }
    var settingsTabRemote: String {
        switch language {
        case .fr: return "iPhone"
        case .en: return "iPhone"
        case .es: return "iPhone"
        case .de: return "iPhone"
        case .it: return "iPhone"
        }
    }
    var settingsTabAdvanced: String {
        switch language {
        case .fr: return "Avancé"
        case .en: return "Advanced"
        case .es: return "Avanzado"
        case .de: return "Erweitert"
        case .it: return "Avanzate"
        }
    }

    // MARK: - Settings: General tab
    var settingsGeneralSection: String {
        switch language {
        case .fr: return "Interface"
        case .en: return "Interface"
        case .es: return "Interfaz"
        case .de: return "Oberfläche"
        case .it: return "Interfaccia"
        }
    }
    var settingsGeneralStatusItem: String {
        switch language {
        case .fr: return "Icône dans la barre des menus"
        case .en: return "Show icon in menu bar"
        case .es: return "Ícono en la barra de menús"
        case .de: return "Symbol in der Menüleiste anzeigen"
        case .it: return "Mostra icona nella barra dei menu"
        }
    }

    // MARK: - Settings: Watch tab
    var settingsWatchSectionTitle: String {
        switch language {
        case .fr: return "Mode surveillance"
        case .en: return "Watch mode"
        case .es: return "Modo vigilancia"
        case .de: return "Überwachungsmodus"
        case .it: return "Modalità sorveglia"
        }
    }
    var settingsWatchAutoAdd: String {
        switch language {
        case .fr: return "Ajout automatique des cartes / disques externes"
        case .en: return "Auto-add inserted cards / external drives"
        case .es: return "Añadir automáticamente las tarjetas / discos externos"
        case .de: return "Eingelegte Karten/externe Laufwerke automatisch hinzufügen"
        case .it: return "Aggiungi automaticamente schede/drive inseriti"
        }
    }
    var settingsWatchAutoStart: String {
        switch language {
        case .fr: return "Lancement automatique de la copie"
        case .en: return "Auto-start the copy"
        case .es: return "Iniciar la copia automáticamente"
        case .de: return "Kopie automatisch starten"
        case .it: return "Avvia automaticamente la copia"
        }
    }
    var settingsWatchFooter: String {
        switch language {
        case .fr: return "Quand activé, toute carte ou disque externe inséré est ajouté en source. Si le lancement automatique est aussi activé et que des destinations sont configurées, la copie démarre immédiatement."
        case .en: return "When enabled, any inserted card or external drive is added as a source. If auto-start is also on and destinations are configured, the copy begins immediately."
        case .es: return "Si está activado, cualquier tarjeta o disco externo insertado se añade como fuente. Con el inicio automático activado y destinos configurados, la copia empieza al instante."
        case .de: return "Wenn aktiviert, wird jede eingelegte Karte oder externes Laufwerk als Quelle hinzugefügt. Falls Auto-Start ebenfalls aktiviert ist und Ziele konfiguriert sind, beginnt die Kopie sofort."
        case .it: return "Se abilitato, qualsiasi scheda o drive esterno inserito viene aggiunto come sorgente. Se anche l'auto-avvio è attivo e le destinazioni sono configurate, la copia inizia immediatamente."
        }
    }

    // MARK: - Settings: Integrations tab
    var settingsIntegrationsSlackHeader: String {
        switch language {
        case .fr: return "Notification Slack"
        case .en: return "Slack notification"
        case .es: return "Notificación Slack"
        case .de: return "Slack-Benachrichtigung"
        case .it: return "Notifica Slack"
        }
    }
    var settingsIntegrationsSlackPlaceholder: String {
        switch language {
        case .fr: return "URL Slack"
        case .en: return "Slack URL"
        case .es: return "URL de Slack"
        case .de: return "Slack-URL"
        case .it: return "URL Slack"
        }
    }
    var settingsIntegrationsSlackFooter: String {
        switch language {
        case .fr: return "Crée un Incoming Webhook dans Slack → colle l'URL ci-dessus. Un message est envoyé à la fin de chaque copie."
        case .en: return "Create an Incoming Webhook in Slack → paste the URL above. A message is posted at the end of every copy."
        case .es: return "Crea un Incoming Webhook en Slack → pega la URL arriba. Se envía un mensaje al final de cada copia."
        case .de: return "Erstellen Sie einen Incoming Webhook in Slack → fügen Sie die URL oben ein. Am Ende jeder Kopie wird eine Nachricht gepostet."
        case .it: return "Crea un Incoming Webhook in Slack → incolla l'URL sopra. Un messaggio viene pubblicato al termine di ogni copia."
        }
    }
    var settingsIntegrationsWebhookHeader: String {
        switch language {
        case .fr: return "Webhook générique (Email / Zapier / Make)"
        case .en: return "Generic webhook (Email / Zapier / Make)"
        case .es: return "Webhook genérico (Email / Zapier / Make)"
        case .de: return "Generischer Webhook (E-Mail / Zapier / Make)"
        case .it: return "Webhook generico (Email / Zapier / Make)"
        }
    }
    var settingsIntegrationsWebhookPlaceholder: String {
        switch language {
        case .fr: return "URL générique"
        case .en: return "Generic URL"
        case .es: return "URL genérica"
        case .de: return "Generische URL"
        case .it: return "URL generico"
        }
    }
    var settingsIntegrationsWebhookExample: String {
        switch language {
        case .fr: return "https://hooks.zapier.com/… ou Make.com"
        case .en: return "https://hooks.zapier.com/… or Make.com"
        case .es: return "https://hooks.zapier.com/… o Make.com"
        case .de: return "https://hooks.zapier.com/… oder Make.com"
        case .it: return "https://hooks.zapier.com/… o Make.com"
        }
    }
    var settingsIntegrationsWebhookFooter: String {
        switch language {
        case .fr: return "Reçoit un JSON détaillé avec les stats. Compatible avec n'importe quel automate qui accepte un POST JSON."
        case .en: return "Receives a detailed JSON with stats. Compatible with any automation tool that accepts a JSON POST."
        case .es: return "Recibe un JSON detallado con las estadísticas. Compatible con cualquier automatización que acepte un POST JSON."
        case .de: return "Empfängt ein detailliertes JSON mit Statistiken. Kompatibel mit jedem Automatisierungstool, das einen JSON-POST akzeptiert."
        case .it: return "Riceve un JSON dettagliato con statistiche. Compatibile con qualsiasi strumento di automazione che accetta un POST JSON."
        }
    }

    // MARK: - Settings: Advanced tab
    var settingsAdvancedFinderSection: String {
        switch language {
        case .fr: return "Métadonnées Finder"
        case .en: return "Finder metadata"
        case .es: return "Metadatos del Finder"
        case .de: return "Finder-Metadaten"
        case .it: return "Metadati Finder"
        }
    }
    var settingsAdvancedFinderToggle: String {
        switch language {
        case .fr: return "Préserver les tags couleur Finder"
        case .en: return "Preserve Finder color tags"
        case .es: return "Conservar las etiquetas de color del Finder"
        case .de: return "Finder-Farb-Tags beibehalten"
        case .it: return "Mantieni i tag colore del Finder"
        }
    }
    var settingsAdvancedSymlinksSection: String {
        switch language {
        case .fr: return "Liens symboliques"
        case .en: return "Symbolic links"
        case .es: return "Enlaces simbólicos"
        case .de: return "Symbolische Links"
        case .it: return "Link simbolici"
        }
    }
    var settingsAdvancedSymlinksToggle: String {
        switch language {
        case .fr: return "Suivre les symlinks (au lieu de les ignorer)"
        case .en: return "Follow symlinks (instead of skipping them)"
        case .es: return "Seguir los symlinks (en lugar de ignorarlos)"
        case .de: return "Symbolischen Links folgen (statt sie zu überspringen)"
        case .it: return "Segui i symlink (invece di saltarli)"
        }
    }

    // MARK: - Settings: Filters tab
    var settingsFiltersIncludeHeader: String {
        switch language {
        case .fr: return "Extensions à inclure (whitelist)"
        case .en: return "Extensions to include (allowlist)"
        case .es: return "Extensiones a incluir (allowlist)"
        case .de: return "Einzuschließende Erweiterungen (Allowlist)"
        case .it: return "Estensioni da includere (allowlist)"
        }
    }
    var settingsFiltersIncludePlaceholder: String {
        switch language {
        case .fr: return "À inclure"
        case .en: return "Include"
        case .es: return "Incluir"
        case .de: return "Einschließen"
        case .it: return "Includi"
        }
    }
    var settingsFiltersIncludeFooter: String {
        switch language {
        case .fr: return "Si renseigné, **seules** ces extensions seront copiées. Laisser vide pour tout copier."
        case .en: return "If set, **only** these extensions will be copied. Leave blank to copy everything."
        case .es: return "Si se rellena, **solo** estas extensiones se copiarán. Dejar vacío para copiar todo."
        case .de: return "Wenn gesetzt, werden **nur** diese Erweiterungen kopiert. Leer lassen, um alles zu kopieren."
        case .it: return "Se impostato, verranno copiate **solo** queste estensioni. Lascia vuoto per copiare tutto."
        }
    }
    var settingsFiltersExcludeHeader: String {
        switch language {
        case .fr: return "Extensions à exclure (blacklist)"
        case .en: return "Extensions to exclude (blocklist)"
        case .es: return "Extensiones a excluir (blocklist)"
        case .de: return "Auszuschließende Erweiterungen (Blocklist)"
        case .it: return "Estensioni da escludere (blocklist)"
        }
    }
    var settingsFiltersExcludePlaceholder: String {
        switch language {
        case .fr: return "À exclure"
        case .en: return "Exclude"
        case .es: return "Excluir"
        case .de: return "Ausschließen"
        case .it: return "Escludi"
        }
    }
    var settingsFiltersExcludeFooter: String {
        switch language {
        case .fr: return "Ces extensions seront **ignorées** même si elles passent le filtre d'inclusion. Utile pour les fichiers parasites caméra."
        case .en: return "These extensions are **skipped** even if they pass the include filter. Useful for sidecar camera files."
        case .es: return "Estas extensiones se **omiten** incluso si pasan el filtro de inclusión. Útil para archivos auxiliares de cámara."
        case .de: return "Diese Erweiterungen werden **übersprungen**, auch wenn sie den Einschlussfilter passieren. Nützlich für Kamera-Sidecar-Dateien."
        case .it: return "Queste estensioni vengono **saltate** anche se superano il filtro di inclusione. Utile per i file sidecar della fotocamera."
        }
    }
    var settingsFiltersSeparatorHint: String {
        switch language {
        case .fr: return "Séparateurs acceptés : virgule, espace, point-virgule. Le point initial est optionnel — `.mxf` ou `mxf` fonctionne pareil."
        case .en: return "Accepted separators: comma, space, semicolon. The leading dot is optional — `.mxf` or `mxf` both work."
        case .es: return "Separadores aceptados: coma, espacio, punto y coma. El punto inicial es opcional — `.mxf` o `mxf` funcionan igual."
        case .de: return "Akzeptierte Trennzeichen: Komma, Leerzeichen, Semikolon. Der führende Punkt ist optional — `.mxf` oder `mxf` funktionieren beide."
        case .it: return "Separatori accettati: virgola, spazio, punto e virgola. Il punto iniziale è opzionale — `.mxf` o `mxf` funzionano entrambi."
        }
    }

    // MARK: - Settings: Renaming tab
    var settingsRenamingSection: String {
        switch language {
        case .fr: return "Renommage dynamique"
        case .en: return "Dynamic renaming"
        case .es: return "Renombrado dinámico"
        case .de: return "Dynamisches Umbenennen"
        case .it: return "Rinomina dinamica"
        }
    }
    var settingsRenamingTemplate: String {
        switch language {
        case .fr: return "Modèle"
        case .en: return "Template"
        case .es: return "Plantilla"
        case .de: return "Vorlage"
        case .it: return "Template"
        }
    }
    var settingsRenamingPreview: String {
        switch language {
        case .fr: return "Aperçu"
        case .en: return "Preview"
        case .es: return "Vista previa"
        case .de: return "Vorschau"
        case .it: return "Anteprima"
        }
    }
    var settingsRenamingClear: String {
        switch language {
        case .fr: return "Effacer le modèle"
        case .en: return "Clear template"
        case .es: return "Borrar plantilla"
        case .de: return "Vorlage leeren"
        case .it: return "Cancella template"
        }
    }
    var settingsRenamingTokensSection: String {
        switch language {
        case .fr: return "Tokens disponibles"
        case .en: return "Available tokens"
        case .es: return "Tokens disponibles"
        case .de: return "Verfügbare Token"
        case .it: return "Token disponibili"
        }
    }
    var settingsRenamingTokenFilename: String {
        switch language {
        case .fr: return "Nom d'origine sans extension"
        case .en: return "Original name without extension"
        case .es: return "Nombre original sin extensión"
        case .de: return "Originalname ohne Erweiterung"
        case .it: return "Nome originale senza estensione"
        }
    }
    var settingsRenamingTokenExt: String {
        switch language {
        case .fr: return "Extension d'origine"
        case .en: return "Original extension"
        case .es: return "Extensión original"
        case .de: return "Originale Erweiterung"
        case .it: return "Estensione originale"
        }
    }
    var settingsRenamingTokenSource: String {
        switch language {
        case .fr: return "Nom du dossier source"
        case .en: return "Source folder name"
        case .es: return "Nombre de la carpeta origen"
        case .de: return "Quellordnername"
        case .it: return "Nome cartella sorgente"
        }
    }
    var settingsRenamingTokenCamera: String {
        switch language {
        case .fr: return "Caméra détectée (RED, BRAW, ARRI…)"
        case .en: return "Detected camera (RED, BRAW, ARRI…)"
        case .es: return "Cámara detectada (RED, BRAW, ARRI…)"
        case .de: return "Erkannte Kamera (RED, BRAW, ARRI…)"
        case .it: return "Fotocamera rilevata (RED, BRAW, ARRI…)"
        }
    }
    var settingsRenamingTokenDate: String {
        switch language {
        case .fr: return "Date — 2026-06-04"
        case .en: return "Date — 2026-06-04"
        case .es: return "Fecha — 2026-06-04"
        case .de: return "Datum — 2026-06-04"
        case .it: return "Data — 2026-06-04"
        }
    }
    var settingsRenamingTokenTime: String {
        switch language {
        case .fr: return "Heure — 14-32-05"
        case .en: return "Time — 14-32-05"
        case .es: return "Hora — 14-32-05"
        case .de: return "Uhrzeit — 14-32-05"
        case .it: return "Ora — 14-32-05"
        }
    }
    var settingsRenamingTokenCounter: String {
        switch language {
        case .fr: return "Compteur incrémenté"
        case .en: return "Incremented counter"
        case .es: return "Contador incrementado"
        case .de: return "Inkrementierter Zähler"
        case .it: return "Contatore incrementale"
        }
    }
    var settingsRenamingTokenCounterPadded: String {
        switch language {
        case .fr: return "Compteur avec padding (0001…)"
        case .en: return "Padded counter (0001…)"
        case .es: return "Contador con relleno (0001…)"
        case .de: return "Aufgefüllter Zähler (0001…)"
        case .it: return "Contatore con zeri (0001…)"
        }
    }

    // MARK: - Cloud status (RemoteSyncSettingsView)
    var cloudStatusWaitingFirstUpload: String {
        switch language {
        case .fr: return "En attente du premier upload…"
        case .en: return "Waiting for first upload…"
        case .es: return "Esperando el primer envío…"
        case .de: return "Warte auf ersten Upload…"
        case .it: return "In attesa del primo upload…"
        }
    }
    func cloudStatusSyncedRelative(_ relative: String) -> String {
        switch language {
        case .fr: return "Synchronisé — dernier upload \(relative)"
        case .en: return "Synced — last upload \(relative)"
        case .es: return "Sincronizado — último envío \(relative)"
        case .de: return "Synchronisiert — letzter Upload \(relative)"
        case .it: return "Sincronizzato — ultimo upload \(relative)"
        }
    }
    var cloudStatusReady: String {
        switch language {
        case .fr: return "Compte iCloud OK, prêt à publier"
        case .en: return "iCloud account OK, ready to publish"
        case .es: return "Cuenta iCloud OK, lista para publicar"
        case .de: return "iCloud-Konto OK, bereit zum Veröffentlichen"
        case .it: return "Account iCloud OK, pronto a pubblicare"
        }
    }
    var cloudStatusPublishing: String {
        switch language {
        case .fr: return "Publication en cours…"
        case .en: return "Publishing…"
        case .es: return "Publicando…"
        case .de: return "Veröffentlichen…"
        case .it: return "Pubblicazione in corso…"
        }
    }
    var cloudReasonNoAccount: String {
        switch language {
        case .fr: return "Aucun compte iCloud sur ce Mac"
        case .en: return "No iCloud account on this Mac"
        case .es: return "No hay cuenta de iCloud en este Mac"
        case .de: return "Kein iCloud-Konto auf diesem Mac"
        case .it: return "Nessun account iCloud su questo Mac"
        }
    }
    var cloudReasonRestricted: String {
        switch language {
        case .fr: return "Compte iCloud restreint"
        case .en: return "iCloud account restricted"
        case .es: return "Cuenta de iCloud restringida"
        case .de: return "iCloud-Konto eingeschränkt"
        case .it: return "Account iCloud limitato"
        }
    }
    var cloudReasonUndetermined: String {
        switch language {
        case .fr: return "Statut iCloud indéterminé"
        case .en: return "iCloud status undetermined"
        case .es: return "Estado de iCloud indeterminado"
        case .de: return "iCloud-Status unbestimmt"
        case .it: return "Stato iCloud indeterminato"
        }
    }
    var cloudReasonTempUnavailable: String {
        switch language {
        case .fr: return "iCloud temporairement indisponible"
        case .en: return "iCloud temporarily unavailable"
        case .es: return "iCloud temporalmente no disponible"
        case .de: return "iCloud vorübergehend nicht verfügbar"
        case .it: return "iCloud temporaneamente non disponibile"
        }
    }
    var cloudReasonUnknown: String {
        switch language {
        case .fr: return "Statut iCloud inconnu"
        case .en: return "iCloud status unknown"
        case .es: return "Estado de iCloud desconocido"
        case .de: return "iCloud-Status unbekannt"
        case .it: return "Stato iCloud sconosciuto"
        }
    }
    var tooltipEjectVolume: String {
        switch language {
        case .fr: return "Éjecter le volume"
        case .en: return "Eject volume"
        case .es: return "Expulsar el volumen"
        case .de: return "Volume auswerfen"
        case .it: return "Espelli volume"
        }
    }
    var confirmClearJournalTitle: String {
        switch language {
        case .fr: return "Effacer le journal d'activité ?"
        case .en: return "Clear the activity journal?"
        case .es: return "¿Borrar el registro de actividad?"
        case .de: return "Aktivitätsprotokoll leeren?"
        case .it: return "Svuotare il registro attività?"
        }
    }
    var confirmClearJournalMessage: String {
        switch language {
        case .fr: return "Toutes les lignes du journal seront perdues. Cette action ne supprime pas les fichiers copiés."
        case .en: return "All journal entries will be removed. This does not delete any copied file."
        case .es: return "Todas las líneas del registro se perderán. Esta acción no elimina los archivos copiados."
        case .de: return "Alle Protokolleinträge werden entfernt. Kopierte Dateien werden nicht gelöscht."
        case .it: return "Tutte le voci del registro verranno rimosse. Non vengono eliminati file copiati."
        }
    }
    var confirmClearJournalAction: String {
        switch language {
        case .fr: return "Effacer"
        case .en: return "Clear"
        case .es: return "Borrar"
        case .de: return "Leeren"
        case .it: return "Pulisci"
        }
    }

    var sectionDIT: String {
        switch language {
        case .fr: return "Structure DIT"
        case .en: return "DIT structure"
        case .es: return "Estructura DIT"
        case .de: return "DIT-Struktur"
        case .it: return "Struttura DIT"
        }
    }
    var ditToggleTitle: String {
        switch language {
        case .fr: return "Activer l'arborescence DIT"
        case .en: return "Enable DIT folder structure"
        case .es: return "Activar estructura DIT"
        case .de: return "DIT-Ordnerstruktur aktivieren"
        case .it: return "Attiva struttura cartelle DIT"
        }
    }
    var ditToggleSubtitle: String {
        switch language {
        case .fr: return "Crée 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .en: return "Creates 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .es: return "Crea 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .de: return "Erstellt 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        case .it: return "Crea 00_INFOS / 01_RUSHES / 02_MHL / 03_PROXY / 04_LUT"
        }
    }
    var ditProjectPlaceholder: String {
        switch language {
        case .fr: return "Nom du projet (ex: FILM_X_2026)"
        case .en: return "Project name (e.g. FILM_X_2026)"
        case .es: return "Nombre del proyecto (ej: FILM_X_2026)"
        case .de: return "Projektname (z. B. FILM_X_2026)"
        case .it: return "Nome progetto (es. FILM_X_2026)"
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
        case .de: return "REEL-Unterordner pro Dump"
        case .it: return "Sottocartella REEL per dump"
        }
    }
    var ditReelToggleSubtitle: String {
        switch language {
        case .fr: return "Chaque déchargement de carte crée un REEL_001, REEL_002… numéroté par caméra"
        case .en: return "Each card dump creates REEL_001, REEL_002… numbered per camera"
        case .es: return "Cada descarga de tarjeta crea REEL_001, REEL_002… numerado por cámara"
        case .de: return "Jeder Karten-Dump erstellt REEL_001, REEL_002… nummeriert pro Kamera"
        case .it: return "Ogni dump della scheda crea REEL_001, REEL_002… numerati per fotocamera"
        }
    }
    var ditProxyToggleTitle: String {
        switch language {
        case .fr: return "Copier les proxys caméra"
        case .en: return "Copy camera proxies"
        case .es: return "Copiar proxies de cámara"
        case .de: return "Kamera-Proxys kopieren"
        case .it: return "Copia proxy fotocamera"
        }
    }
    var ditProxyToggleSubtitle: String {
        switch language {
        case .fr: return "Route SUB/, PROXY/, suffixe S01… vers 03_PROXY/ au lieu de 01_RUSHES/"
        case .en: return "Routes SUB/, PROXY/, S01… files to 03_PROXY/ instead of 01_RUSHES/"
        case .es: return "Enruta SUB/, PROXY/, S01… a 03_PROXY/ en lugar de 01_RUSHES/"
        case .de: return "Leitet SUB/, PROXY/, S01…-Dateien nach 03_PROXY/ statt 01_RUSHES/ weiter"
        case .it: return "Invia i file SUB/, PROXY/, S01… a 03_PROXY/ invece di 01_RUSHES/"
        }
    }
    var ditReelResetButton: String {
        switch language {
        case .fr: return "Réinitialiser le compteur REEL"
        case .en: return "Reset REEL counter"
        case .es: return "Reiniciar contador REEL"
        case .de: return "REEL-Zähler zurücksetzen"
        case .it: return "Reimposta contatore REEL"
        }
    }
    var ditReelResetConfirmTitle: String {
        switch language {
        case .fr: return "Remettre le compteur REEL à 1 ?"
        case .en: return "Reset REEL counter to 1?"
        case .es: return "¿Reiniciar el contador REEL a 1?"
        case .de: return "REEL-Zähler auf 1 zurücksetzen?"
        case .it: return "Reimpostare il contatore REEL a 1?"
        }
    }
    var ditReelResetConfirmMessage: String {
        switch language {
        case .fr: return "Le prochain dump repartira de REEL_001 sur toutes les destinations configurées. Les dossiers REEL existants sur le disque ne sont pas supprimés."
        case .en: return "The next dump will start back at REEL_001 on every configured destination. Existing REEL folders on disk are not removed."
        case .es: return "La próxima descarga empezará de nuevo en REEL_001 en cada destino. Las carpetas REEL ya existentes no se eliminan."
        case .de: return "Der nächste Dump beginnt wieder bei REEL_001 auf jedem konfigurierten Ziel. Vorhandene REEL-Ordner werden nicht entfernt."
        case .it: return "Il prossimo dump ripartirà da REEL_001 su ogni destinazione configurata. Le cartelle REEL esistenti non vengono rimosse."
        }
    }
    var ditReelResetConfirmAction: String {
        switch language {
        case .fr: return "Réinitialiser"
        case .en: return "Reset"
        case .es: return "Reiniciar"
        case .de: return "Zurücksetzen"
        case .it: return "Reimposta"
        }
    }
    func logReelCounterReset(destinations: Int) -> String {
        switch language {
        case .fr: return "Compteur REEL réinitialisé sur \(destinations) destination(s)"
        case .en: return "REEL counter reset on \(destinations) destination(s)"
        case .es: return "Contador REEL reiniciado en \(destinations) destino(s)"
        case .de: return "REEL-Zähler zurückgesetzt auf \(destinations) Ziel(en)"
        case .it: return "Contatore REEL reimpostato su \(destinations) destinazione/i"
        }
    }
    var ditCameraTagLabel: String {
        switch language {
        case .fr: return "Caméra"
        case .en: return "Camera"
        case .es: return "Cámara"
        case .de: return "Kamera"
        case .it: return "Fotocamera"
        }
    }
    // MARK: - DIT settings tab
    var settingsTabDIT: String {
        switch language {
        case .fr: return "Structure DIT"
        case .en: return "DIT structure"
        case .es: return "Estructura DIT"
        case .de: return "DIT-Struktur"
        case .it: return "Struttura DIT"
        }
    }
    var settingsDITFoldersHeader: String {
        switch language {
        case .fr: return "Noms des dossiers"
        case .en: return "Folder names"
        case .es: return "Nombres de carpetas"
        case .de: return "Ordnernamen"
        case .it: return "Nomi cartelle"
        }
    }
    var settingsDITFoldersFooter: String {
        switch language {
        case .fr: return "Vide = valeur par défaut. Ces noms sont créés à la racine du dossier projet sur chaque destination."
        case .en: return "Blank = default. These folders are created at the project root on every destination."
        case .es: return "Vacío = valor predeterminado. Estas carpetas se crean en la raíz del proyecto en cada destino."
        case .de: return "Leer = Standard. Diese Ordner werden auf jedem Ziel im Projektstamm erstellt."
        case .it: return "Vuoto = predefinito. Queste cartelle vengono create alla radice del progetto su ogni destinazione."
        }
    }
    var settingsDITLabelInfos: String {
        switch language {
        case .fr: return "Dossier infos"
        case .en: return "Info folder"
        case .es: return "Carpeta info"
        case .de: return "Info-Ordner"
        case .it: return "Cartella Info"
        }
    }
    var settingsDITLabelRushes: String {
        switch language {
        case .fr: return "Dossier rushes"
        case .en: return "Rushes folder"
        case .es: return "Carpeta rushes"
        case .de: return "Rushes-Ordner"
        case .it: return "Cartella Rushes"
        }
    }
    var settingsDITLabelMHL: String {
        switch language {
        case .fr: return "Dossier MHL"
        case .en: return "MHL folder"
        case .es: return "Carpeta MHL"
        case .de: return "MHL-Ordner"
        case .it: return "Cartella MHL"
        }
    }
    var settingsDITLabelProxy: String {
        switch language {
        case .fr: return "Dossier proxy"
        case .en: return "Proxy folder"
        case .es: return "Carpeta proxy"
        case .de: return "Proxy-Ordner"
        case .it: return "Cartella Proxy"
        }
    }
    var settingsDITLabelLUT: String {
        switch language {
        case .fr: return "Dossier LUT"
        case .en: return "LUT folder"
        case .es: return "Carpeta LUT"
        case .de: return "LUT-Ordner"
        case .it: return "Cartella LUT"
        }
    }
    var settingsDITReportHeader: String {
        switch language {
        case .fr: return "Nom du rapport"
        case .en: return "Report filename"
        case .es: return "Nombre del informe"
        case .de: return "Berichtsdateiname"
        case .it: return "Nome file rapporto"
        }
    }
    var settingsDITReportPrefix: String {
        switch language {
        case .fr: return "Préfixe du rapport DIT"
        case .en: return "DIT report prefix"
        case .es: return "Prefijo del informe DIT"
        case .de: return "DIT-Berichtspräfix"
        case .it: return "Prefisso rapporto DIT"
        }
    }
    func settingsDITReportPreview(prefix: String, date: String) -> String {
        switch language {
        case .fr: return "Nom final : `\(prefix)_\(date).pdf`"
        case .en: return "Final name: `\(prefix)_\(date).pdf`"
        case .es: return "Nombre final: `\(prefix)_\(date).pdf`"
        case .de: return "Endname: `\(prefix)_\(date).pdf`"
        case .it: return "Nome finale: `\(prefix)_\(date).pdf`"
        }
    }
    var settingsDITExtraHeader: String {
        switch language {
        case .fr: return "Dossiers supplémentaires"
        case .en: return "Extra folders"
        case .es: return "Carpetas adicionales"
        case .de: return "Zusätzliche Ordner"
        case .it: return "Cartelle extra"
        }
    }
    var settingsDITExtraFooter: String {
        switch language {
        case .fr: return "Crée des dossiers vides à la racine du projet en plus des 5 standards (ex: 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .en: return "Creates empty folders at the project root in addition to the 5 standard ones (e.g. 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .es: return "Crea carpetas vacías en la raíz del proyecto además de las 5 estándar (ej: 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .de: return "Erstellt leere Ordner im Projektstamm zusätzlich zu den 5 Standardordnern (z. B. 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        case .it: return "Crea cartelle vuote alla radice del progetto in aggiunta alle 5 standard (es. 05_EDIT, 06_DELIVERABLES, MASTER_AUDIO…)."
        }
    }
    var settingsDITExtraPlaceholder: String {
        switch language {
        case .fr: return "Nom du dossier"
        case .en: return "Folder name"
        case .es: return "Nombre de carpeta"
        case .de: return "Ordnername"
        case .it: return "Nome cartella"
        }
    }
    var settingsDITAddFolder: String {
        switch language {
        case .fr: return "Ajouter un dossier"
        case .en: return "Add folder"
        case .es: return "Añadir carpeta"
        case .de: return "Ordner hinzufügen"
        case .it: return "Aggiungi cartella"
        }
    }
    var settingsDITReset: String {
        switch language {
        case .fr: return "Réinitialiser aux valeurs par défaut"
        case .en: return "Reset to defaults"
        case .es: return "Restablecer valores predeterminados"
        case .de: return "Auf Standard zurücksetzen"
        case .it: return "Ripristina predefiniti"
        }
    }
    var menuStart: String {
        switch language {
        case .fr: return "Lancer"
        case .en: return "Start"
        case .es: return "Iniciar"
        case .de: return "Start"
        case .it: return "Avvia"
        }
    }
    var menuCancel: String {
        switch language {
        case .fr: return "Annuler"
        case .en: return "Cancel"
        case .es: return "Cancelar"
        case .de: return "Abbrechen"
        case .it: return "Annulla"
        }
    }
    var menuAddToQueue: String {
        switch language {
        case .fr: return "Ajouter à la file d'attente"
        case .en: return "Add to queue"
        case .es: return "Añadir a la cola"
        case .de: return "Zur Warteschlange hinzufügen"
        case .it: return "Aggiungi alla coda"
        }
    }
    var menuClearQueue: String {
        switch language {
        case .fr: return "Vider la file"
        case .en: return "Clear queue"
        case .es: return "Vaciar la cola"
        case .de: return "Warteschlange leeren"
        case .it: return "Svuota coda"
        }
    }
    var menuSpeedTest: String {
        switch language {
        case .fr: return "Test vitesse drive"
        case .en: return "Drive speed test"
        case .es: return "Prueba velocidad"
        case .de: return "Laufwerk-Geschwindigkeitstest"
        case .it: return "Test velocità disco"
        }
    }
    var menuNoDest: String {
        switch language {
        case .fr: return "Aucune destination"
        case .en: return "No destination"
        case .es: return "Ningún destino"
        case .de: return "Kein Ziel"
        case .it: return "Nessuna destinazione"
        }
    }
    var menuToggleSim: String {
        switch language {
        case .fr: return "Simulation"
        case .en: return "Simulation"
        case .es: return "Simulación"
        case .de: return "Simulation"
        case .it: return "Simulazione"
        }
    }
    var menuTogglePreserve: String {
        switch language {
        case .fr: return "Préserver la structure"
        case .en: return "Preserve structure"
        case .es: return "Conservar estructura"
        case .de: return "Struktur beibehalten"
        case .it: return "Mantieni struttura"
        }
    }
    var menuToggleEjectAfter: String {
        switch language {
        case .fr: return "Éjecter après copie"
        case .en: return "Eject after copy"
        case .es: return "Expulsar tras copia"
        case .de: return "Nach dem Kopieren auswerfen"
        case .it: return "Espelli dopo la copia"
        }
    }
    var menuToggleNotif: String {
        switch language {
        case .fr: return "Notification système"
        case .en: return "System notification"
        case .es: return "Notificación del sistema"
        case .de: return "Systembenachrichtigung"
        case .it: return "Notifica di sistema"
        }
    }
    var menuToggleSkipSystem: String {
        switch language {
        case .fr: return "Ignorer fichiers système"
        case .en: return "Skip system files"
        case .es: return "Omitir archivos de sistema"
        case .de: return "Systemdateien überspringen"
        case .it: return "Salta file di sistema"
        }
    }
    var menuToggleOrganize: String {
        switch language {
        case .fr: return "Organiser par date"
        case .en: return "Organize by date"
        case .es: return "Organizar por fecha"
        case .de: return "Nach Datum ordnen"
        case .it: return "Organizza per data"
        }
    }
    var menuToggleThumbs: String {
        switch language {
        case .fr: return "Vignettes dans le PDF"
        case .en: return "Thumbnails in PDF"
        case .es: return "Miniaturas en PDF"
        case .de: return "Vorschaubilder in PDF"
        case .it: return "Miniature nel PDF"
        }
    }
    var menuToggleDuplicates: String {
        switch language {
        case .fr: return "Détection des doublons"
        case .en: return "Duplicate detection"
        case .es: return "Detección duplicados"
        case .de: return "Duplikatserkennung"
        case .it: return "Rilevamento duplicati"
        }
    }
    var menuAlgo: String {
        switch language {
        case .fr: return "Algorithme"
        case .en: return "Algorithm"
        case .es: return "Algoritmo"
        case .de: return "Algorithmus"
        case .it: return "Algoritmo"
        }
    }
    var menuBandwidthLimit: String {
        switch language {
        case .fr: return "Limite de débit"
        case .en: return "Bandwidth limit"
        case .es: return "Límite ancho"
        case .de: return "Bandbreitengrenze"
        case .it: return "Limite di banda"
        }
    }
    var menuVerifyMHL: String {
        switch language {
        case .fr: return "Vérifier MHL…"
        case .en: return "Verify MHL…"
        case .es: return "Verificar MHL…"
        case .de: return "MHL verifizieren…"
        case .it: return "Verifica MHL…"
        }
    }
    var menuExportMHLv1: String {
        switch language {
        case .fr: return "Exporter MHL v1…"
        case .en: return "Export MHL v1…"
        case .es: return "Exportar MHL v1…"
        case .de: return "MHL v1 exportieren…"
        case .it: return "Esporta MHL v1…"
        }
    }
    var menuExportASCMHL: String {
        switch language {
        case .fr: return "Exporter ASCMHL v2…"
        case .en: return "Export ASCMHL v2…"
        case .es: return "Exportar ASCMHL v2…"
        case .de: return "ASC-MHL v2 exportieren…"
        case .it: return "Esporta ASC-MHL v2…"
        }
    }
    var menuExportCSV: String {
        switch language {
        case .fr: return "Exporter CSV…"
        case .en: return "Export CSV…"
        case .es: return "Exportar CSV…"
        case .de: return "CSV exportieren…"
        case .it: return "Esporta CSV…"
        }
    }
    var menuExportHTML: String {
        switch language {
        case .fr: return "Exporter HTML…"
        case .en: return "Export HTML…"
        case .es: return "Exportar HTML…"
        case .de: return "HTML exportieren…"
        case .it: return "Esporta HTML…"
        }
    }
    var menuHistoryOpen2: String {
        switch language {
        case .fr: return "Historique…"
        case .en: return "History…"
        case .es: return "Historial…"
        case .de: return "Verlauf…"
        case .it: return "Cronologia…"
        }
    }
    var menuClearLog: String {
        switch language {
        case .fr: return "Effacer le journal"
        case .en: return "Clear log"
        case .es: return "Limpiar registro"
        case .de: return "Protokoll leeren"
        case .it: return "Pulisci registro"
        }
    }
    var menuSaveCurrent: String {
        switch language {
        case .fr: return "Enregistrer le profil actuel…"
        case .en: return "Save current preset…"
        case .es: return "Guardar perfil actual…"
        case .de: return "Aktuelle Vorlage speichern…"
        case .it: return "Salva preset corrente…"
        }
    }
    var menuManagePresets: String {
        switch language {
        case .fr: return "Gérer les profils…"
        case .en: return "Manage presets…"
        case .es: return "Gestionar perfiles…"
        case .de: return "Vorlagen verwalten…"
        case .it: return "Gestisci preset…"
        }
    }
    var menuNoPreset: String {
        switch language {
        case .fr: return "Aucun profil enregistré"
        case .en: return "No saved preset"
        case .es: return "Ningún perfil"
        case .de: return "Keine gespeicherte Vorlage"
        case .it: return "Nessun preset salvato"
        }
    }
    var menuUnlimited: String {
        switch language {
        case .fr: return "Illimité"
        case .en: return "Unlimited"
        case .es: return "Ilimitado"
        case .de: return "Unbegrenzt"
        case .it: return "Illimitato"
        }
    }

    // MARK: - Watch + webhook + tags

    func logWatchAutoAdded(_ name: String) -> String {
        switch language {
        case .fr: return "Surveillance — \(name) ajouté automatiquement"
        case .en: return "Watch — auto-added \(name)"
        case .es: return "Vigilancia — \(name) añadido automáticamente"
        case .de: return "Überwachung — \(name) automatisch hinzugefügt"
        case .it: return "Sorveglia — \(name) aggiunto automaticamente"
        }
    }
    var logWatchAutoStarted: String {
        switch language {
        case .fr: return "Surveillance — lancement automatique"
        case .en: return "Watch — auto-started copy"
        case .es: return "Vigilancia — copia iniciada automáticamente"
        case .de: return "Überwachung — Kopie automatisch gestartet"
        case .it: return "Sorveglia — copia avviata automaticamente"
        }
    }
    var logWebhookSent: String {
        switch language {
        case .fr: return "Webhook envoyé"
        case .en: return "Webhook sent"
        case .es: return "Webhook enviado"
        case .de: return "Webhook gesendet"
        case .it: return "Webhook inviato"
        }
    }
    // MARK: - License

    var sectionLicense: String {
        switch language {
        case .fr: return "Licence"
        case .en: return "License"
        case .es: return "Licencia"
        case .de: return "Lizenz"
        case .it: return "Licenza"
        }
    }
    var licenseStateTrial: String {
        switch language {
        case .fr: return "Essai gratuit"
        case .en: return "Free trial"
        case .es: return "Prueba gratuita"
        case .de: return "Kostenlose Testversion"
        case .it: return "Prova gratuita"
        }
    }
    func licenseTrialRemaining(days: Int, transfers: Int) -> String {
        switch language {
        case .fr: return "\(days) j · \(transfers) transferts restants"
        case .en: return "\(days)d · \(transfers) transfers left"
        case .es: return "\(days) d · \(transfers) transferencias restantes"
        case .de: return "\(days)T · \(transfers) Übertragungen übrig"
        case .it: return "\(days)g · \(transfers) trasferimenti rimasti"
        }
    }
    var licenseStateExpired: String {
        switch language {
        case .fr: return "Essai expiré"
        case .en: return "Trial expired"
        case .es: return "Prueba expirada"
        case .de: return "Testversion abgelaufen"
        case .it: return "Versione di prova scaduta"
        }
    }
    var licenseStateActive: String {
        switch language {
        case .fr: return "Licence active"
        case .en: return "License active"
        case .es: return "Licencia activa"
        case .de: return "Lizenz aktiv"
        case .it: return "Licenza attiva"
        }
    }
    var licenseFieldEmail: String {
        switch language {
        case .fr: return "Email d'achat"
        case .en: return "Purchase email"
        case .es: return "Email de compra"
        case .de: return "Kauf-E-Mail"
        case .it: return "Email di acquisto"
        }
    }
    var licenseFieldKey: String {
        switch language {
        case .fr: return "Clé de licence"
        case .en: return "License key"
        case .es: return "Clave de licencia"
        case .de: return "Lizenzschlüssel"
        case .it: return "Chiave di licenza"
        }
    }
    var licenseActivate: String {
        switch language {
        case .fr: return "Activer"
        case .en: return "Activate"
        case .es: return "Activar"
        case .de: return "Aktivieren"
        case .it: return "Attiva"
        }
    }
    var licenseInvalid: String {
        switch language {
        case .fr: return "Email ou clé invalide"
        case .en: return "Invalid email or key"
        case .es: return "Email o clave no válidos"
        case .de: return "Ungültige E-Mail oder Schlüssel"
        case .it: return "Email o chiave non validi"
        }
    }
    var licenseDeactivate: String {
        switch language {
        case .fr: return "Désactiver sur ce poste"
        case .en: return "Deactivate on this machine"
        case .es: return "Desactivar en este equipo"
        case .de: return "Auf diesem Gerät deaktivieren"
        case .it: return "Disattiva su questo computer"
        }
    }
    func licenseBuyAt(_ price: String) -> String {
        switch language {
        case .fr: return "Acheter — \(price)"
        case .en: return "Buy — \(price)"
        case .es: return "Comprar — \(price)"
        case .de: return "Kaufen — \(price)"
        case .it: return "Acquista — \(price)"
        }
    }
    var licenseTwoMachineHint: String {
        switch language {
        case .fr: return "Une licence couvre jusqu'à 2 postes."
        case .en: return "One license covers up to 2 machines."
        case .es: return "Una licencia cubre hasta 2 equipos."
        case .de: return "Eine Lizenz gilt für bis zu 2 Geräte."
        case .it: return "Una licenza copre fino a 2 computer."
        }
    }
    var logLicenseExpired: String {
        switch language {
        case .fr: return "Essai expiré — entrez une licence pour continuer"
        case .en: return "Trial expired — enter a license to continue"
        case .es: return "Prueba expirada — introduce una licencia"
        case .de: return "Testversion abgelaufen — Lizenz eingeben, um fortzufahren"
        case .it: return "Versione di prova scaduta — inserisci una licenza per continuare"
        }
    }
    var badgeTrial: String {
        switch language {
        case .fr: return "ESSAI"
        case .en: return "TRIAL"
        case .es: return "PRUEBA"
        case .de: return "TEST"
        case .it: return "PROVA"
        }
    }
    var badgeExpired: String {
        switch language {
        case .fr: return "EXPIRÉ"
        case .en: return "EXPIRED"
        case .es: return "EXPIRADO"
        case .de: return "ABGELAUFEN"
        case .it: return "SCADUTA"
        }
    }
    var badgeLicensed: String {
        switch language {
        case .fr: return "LICENCE"
        case .en: return "LICENSED"
        case .es: return "LICENCIA"
        case .de: return "LIZENZIERT"
        case .it: return "CON LICENZA"
        }
    }

    var quickToggleWatch: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        case .de: return "Überwachen"
        case .it: return "Sorveglia"
        }
    }
    var quickToggleAutoStart: String {
        switch language {
        case .fr: return "Auto-start"
        case .en: return "Auto-start"
        case .es: return "Inicio automático"
        case .de: return "Kopie automatisch starten"
        case .it: return "Avvia copia automaticamente"
        }
    }
    var quickToggleAutoEject: String {
        switch language {
        case .fr: return "Auto eject"
        case .en: return "Auto eject"
        case .es: return "Expulsión auto."
        case .de: return "Auto-Auswerfen"
        case .it: return "Espulsione auto"
        }
    }
    var quickToggleSkipDuplicates: String {
        switch language {
        case .fr: return "Doublons"
        case .en: return "Dupes"
        case .es: return "Duplicados"
        case .de: return "Duplikate"
        case .it: return "Duplicati"
        }
    }
    var settingsParallelSection: String {
        switch language {
        case .fr: return "Copie multi-cartes"
        case .en: return "Multi-card copy"
        case .es: return "Copia multi-tarjeta"
        case .de: return "Mehrkarten-Kopie"
        case .it: return "Copia multi-scheda"
        }
    }
    var settingsParallelToggle: String {
        switch language {
        case .fr: return "Copier les sources en parallèle"
        case .en: return "Copy sources in parallel"
        case .es: return "Copiar orígenes en paralelo"
        case .de: return "Quellen parallel kopieren"
        case .it: return "Copia sorgenti in parallelo"
        }
    }
    var settingsParallelFooter: String {
        switch language {
        case .fr: return "Chaque carte source a son propre pipeline de copie et de vérification — plusieurs cartes se déchargent en même temps. Recommandé uniquement vers un SSD/NVMe ; sur un disque dur mécanique, la copie séquentielle reste plus rapide."
        case .en: return "Each source card gets its own copy + verification pipeline — several cards offload at the same time. Recommended only toward an SSD/NVMe; on a spinning hard drive, sequential copy stays faster."
        case .es: return "Cada tarjeta origen tiene su propio flujo de copia y verificación — varias tarjetas se descargan a la vez. Recomendado solo hacia un SSD/NVMe; en un disco duro mecánico, la copia secuencial sigue siendo más rápida."
        case .de: return "Jede Quellkarte erhält ihre eigene Kopier- und Verifikations-Pipeline — mehrere Karten werden gleichzeitig ausgelesen. Nur für SSD/NVMe empfohlen; auf einem Festplattenlaufwerk bleibt die sequenzielle Kopie schneller."
        case .it: return "Ogni scheda sorgente ottiene la propria pipeline di copia + verifica — più schede si scaricano contemporaneamente. Consigliato solo verso SSD/NVMe; su un hard disk meccanico la copia sequenziale rimane più veloce."
        }
    }
    var menuWatchSection: String {
        switch language {
        case .fr: return "Surveillance"
        case .en: return "Watch"
        case .es: return "Vigilancia"
        case .de: return "Überwachen"
        case .it: return "Sorveglia"
        }
    }
    var menuWatchAutoAdd: String {
        switch language {
        case .fr: return "Ajout automatique des cartes"
        case .en: return "Auto-add cards"
        case .es: return "Añadir tarjetas automáticamente"
        case .de: return "Karten automatisch hinzufügen"
        case .it: return "Aggiungi schede automaticamente"
        }
    }
    var menuWatchAutoStart: String {
        switch language {
        case .fr: return "Lancement automatique"
        case .en: return "Auto-start copy"
        case .es: return "Inicio automático"
        case .de: return "Kopie automatisch starten"
        case .it: return "Avvia copia automaticamente"
        }
    }
    var menuExportJournal: String {
        switch language {
        case .fr: return "Exporter le journal…"
        case .en: return "Export log…"
        case .es: return "Exportar registro…"
        case .de: return "Protokoll exportieren…"
        case .it: return "Esporta registro…"
        }
    }
    var panelExportJournal: String {
        switch language {
        case .fr: return "Exporter le journal"
        case .en: return "Export log"
        case .es: return "Exportar registro"
        case .de: return "Protokoll exportieren"
        case .it: return "Esporta registro"
        }
    }
    var buttonJournal: String {
        switch language {
        case .fr: return "Journal"
        case .en: return "Log"
        case .es: return "Registro"
        case .de: return "Protokoll"
        case .it: return "Registro"
        }
    }
    var journalHeaderTitle: String {
        switch language {
        case .fr: return "MisiCopy — Journal d'activité"
        case .en: return "MisiCopy — Activity log"
        case .es: return "MisiCopy — Registro de actividad"
        case .de: return "MisiCopy — Aktivitätsprotokoll"
        case .it: return "MisiCopy — Registro attività"
        }
    }
    func journalHeaderExportedAt(_ iso: String) -> String {
        switch language {
        case .fr: return "Exporté le \(iso)"
        case .en: return "Exported at \(iso)"
        case .es: return "Exportado el \(iso)"
        case .de: return "Exportiert am \(iso)"
        case .it: return "Esportato il \(iso)"
        }
    }
    func journalHeaderEntries(_ n: Int) -> String {
        switch language {
        case .fr: return "\(n) entrée(s)"
        case .en: return n == 1 ? "1 entry" : "\(n) entries"
        case .es: return "\(n) entrada(s)"
        case .de: return "\(n) entrada(s)"
        case .it: return "\(n) entrada(s)"
        }
    }

    // MARK: - Confort pro (Phase P3+)

    var logPaused: String {
        switch language {
        case .fr: return "Copie en pause"
        case .en: return "Copy paused"
        case .es: return "Copia en pausa"
        case .de: return "Kopie pausiert"
        case .it: return "Copia in pausa"
        }
    }
    var logResumed: String {
        switch language {
        case .fr: return "Reprise de la copie"
        case .en: return "Copy resumed"
        case .es: return "Copia reanudada"
        case .de: return "Kopie fortgesetzt"
        case .it: return "Copia ripresa"
        }
    }
    var actionPause: String {
        switch language {
        case .fr: return "Pause"
        case .en: return "Pause"
        case .es: return "Pausar"
        case .de: return "Pause"
        case .it: return "Pausa"
        }
    }
    var actionResume: String {
        switch language {
        case .fr: return "Reprendre"
        case .en: return "Resume"
        case .es: return "Reanudar"
        case .de: return "Fortsetzen"
        case .it: return "Riprendi"
        }
    }
    func logDuplicateSkipped(_ file: String, _ destination: String) -> String {
        switch language {
        case .fr: return "\(file) — déjà présent à \(destination), copie évitée"
        case .en: return "\(file) — already present at \(destination), copy skipped"
        case .es: return "\(file) — ya presente en \(destination), copia omitida"
        case .de: return "\(file) — bereits vorhanden in \(destination), Kopie übersprungen"
        case .it: return "\(file) — già presente in \(destination), copia saltata"
        }
    }
    func logSpeedTestStart(_ name: String) -> String {
        switch language {
        case .fr: return "Test vitesse — \(name)…"
        case .en: return "Speed test — \(name)…"
        case .es: return "Test velocidad — \(name)…"
        case .de: return "Geschwindigkeitstest — \(name)…"
        case .it: return "Test velocità — \(name)…"
        }
    }
    func logSpeedTestResult(folder: String, writeMBs: Double, readMBs: Double) -> String {
        let w = String(format: "%.0f", writeMBs)
        let r = String(format: "%.0f", readMBs)
        switch language {
        case .fr: return "\(folder) — écriture \(w) MB/s, lecture \(r) MB/s"
        case .en: return "\(folder) — write \(w) MB/s, read \(r) MB/s"
        case .es: return "\(folder) — escritura \(w) MB/s, lectura \(r) MB/s"
        case .de: return "\(folder) — Schreiben \(w) MB/s, Lesen \(r) MB/s"
        case .it: return "\(folder) — scrittura \(w) MB/s, lettura \(r) MB/s"
        }
    }
    func logSpeedTestFailed(_ reason: String) -> String {
        switch language {
        case .fr: return "Test vitesse échoué — \(reason)"
        case .en: return "Speed test failed — \(reason)"
        case .es: return "Test velocidad fallido — \(reason)"
        case .de: return "Geschwindigkeitstest fehlgeschlagen — \(reason)"
        case .it: return "Test velocità fallito — \(reason)"
        }
    }

    // MARK: - History / bandwidth / status item

    var menuHistory: String {
        switch language {
        case .fr: return "Historique"
        case .en: return "History"
        case .es: return "Historial"
        case .de: return "Verlauf"
        case .it: return "Cronologia"
        }
    }
    var menuHistoryOpen: String {
        switch language {
        case .fr: return "Ouvrir l'historique…"
        case .en: return "Open history…"
        case .es: return "Abrir historial…"
        case .de: return "Verlauf öffnen…"
        case .it: return "Apri cronologia…"
        }
    }
    var historyEmpty: String {
        switch language {
        case .fr: return "Aucune session enregistrée"
        case .en: return "No session recorded"
        case .es: return "Ninguna sesión registrada"
        case .de: return "Keine Sitzung aufgezeichnet"
        case .it: return "Nessuna sessione registrata"
        }
    }
    var buttonClearHistory: String {
        switch language {
        case .fr: return "Tout effacer"
        case .en: return "Clear all"
        case .es: return "Borrar todo"
        case .de: return "Alle löschen"
        case .it: return "Cancella tutto"
        }
    }
    var toggleStatusItem: String {
        switch language {
        case .fr: return "Icône dans la barre des menus"
        case .en: return "Show menu bar icon"
        case .es: return "Icono en barra de menús"
        case .de: return "Menüleistensymbol anzeigen"
        case .it: return "Mostra icona barra menu"
        }
    }
    var labelBandwidth: String {
        switch language {
        case .fr: return "Limite de débit"
        case .en: return "Bandwidth limit"
        case .es: return "Límite de ancho"
        case .de: return "Bandbreitengrenze"
        case .it: return "Limite di banda"
        }
    }
    var bandwidthUnlimited: String {
        switch language {
        case .fr: return "Illimité"
        case .en: return "Unlimited"
        case .es: return "Ilimitado"
        case .de: return "Unbegrenzt"
        case .it: return "Illimitato"
        }
    }

    // MARK: - Queue & resume

    var sectionQueue: String {
        switch language {
        case .fr: return "File d'attente"
        case .en: return "Queue"
        case .es: return "Cola"
        case .de: return "Warteschlange"
        case .it: return "Coda"
        }
    }
    var buttonAddToQueue: String {
        switch language {
        case .fr: return "Ajouter à la file"
        case .en: return "Add to queue"
        case .es: return "Añadir a la cola"
        case .de: return "Zur Warteschlange hinzufügen"
        case .it: return "Aggiungi alla coda"
        }
    }
    var buttonClearQueue: String {
        switch language {
        case .fr: return "Vider"
        case .en: return "Clear"
        case .es: return "Vaciar"
        case .de: return "Leeren"
        case .it: return "Pulisci"
        }
    }
    func logJobQueued(_ summary: String) -> String {
        switch language {
        case .fr: return "Tâche ajoutée à la file — \(summary)"
        case .en: return "Job queued — \(summary)"
        case .es: return "Tarea encolada — \(summary)"
        case .de: return "Auftrag in Warteschlange — \(summary)"
        case .it: return "Lavoro in coda — \(summary)"
        }
    }
    func logQueueStarting(_ summary: String) -> String {
        switch language {
        case .fr: return "Démarrage de la tâche suivante — \(summary)"
        case .en: return "Starting next job — \(summary)"
        case .es: return "Iniciando siguiente tarea — \(summary)"
        case .de: return "Nächsten Auftrag starten — \(summary)"
        case .it: return "Avvio prossimo lavoro — \(summary)"
        }
    }
    var logQueueNeedsSrcDest: String {
        switch language {
        case .fr: return "Impossible de mettre en file — source ou destination manquante"
        case .en: return "Cannot queue — source or destination missing"
        case .es: return "No se puede encolar — falta origen o destino"
        case .de: return "Kann nicht in Warteschlange — Quelle oder Ziel fehlt"
        case .it: return "Impossibile accodare — sorgente o destinazione mancante"
        }
    }

    var sessionResumeTitle: String {
        switch language {
        case .fr: return "Session précédente détectée"
        case .en: return "Previous session detected"
        case .es: return "Sesión anterior detectada"
        case .de: return "Vorherige Sitzung erkannt"
        case .it: return "Sessione precedente rilevata"
        }
    }
    func sessionResumeSubtitle(savedAt: Date) -> String {
        let date = formatDateTime(savedAt)
        switch language {
        case .fr: return "Restaurer sources, destinations et options — \(date)"
        case .en: return "Restore sources, destinations and options — \(date)"
        case .es: return "Restaurar orígenes, destinos y opciones — \(date)"
        case .de: return "Quellen, Ziele und Optionen wiederherstellen — \(date)"
        case .it: return "Ripristina sorgenti, destinazioni e opzioni — \(date)"
        }
    }
    var buttonResume: String {
        switch language {
        case .fr: return "Reprendre"
        case .en: return "Resume"
        case .es: return "Reanudar"
        case .de: return "Fortsetzen"
        case .it: return "Riprendi"
        }
    }
    var logSessionResumed: String {
        switch language {
        case .fr: return "Session précédente restaurée"
        case .en: return "Previous session restored"
        case .es: return "Sesión anterior restaurada"
        case .de: return "Vorherige Sitzung wiederhergestellt"
        case .it: return "Sessione precedente ripristinata"
        }
    }

    // MARK: - Presets / Verify

    var toggleOrganizeByDate: String {
        switch language {
        case .fr: return "Organiser par date"
        case .en: return "Organize by date"
        case .es: return "Organizar por fecha"
        case .de: return "Nach Datum ordnen"
        case .it: return "Organizza per data"
        }
    }
    var menuPresets: String {
        switch language {
        case .fr: return "Profils"
        case .en: return "Presets"
        case .es: return "Perfiles"
        case .de: return "Vorlagen"
        case .it: return "Preset"
        }
    }
    var menuPresetsApply: String {
        switch language {
        case .fr: return "Appliquer un profil"
        case .en: return "Apply preset"
        case .es: return "Aplicar perfil"
        case .de: return "Vorlage anwenden"
        case .it: return "Applica preset"
        }
    }
    var menuPresetsSave: String {
        switch language {
        case .fr: return "Enregistrer le profil actuel…"
        case .en: return "Save current preset…"
        case .es: return "Guardar perfil actual…"
        case .de: return "Aktuelle Vorlage speichern…"
        case .it: return "Salva preset corrente…"
        }
    }
    var menuPresetsManage: String {
        switch language {
        case .fr: return "Gérer les profils…"
        case .en: return "Manage presets…"
        case .es: return "Gestionar perfiles…"
        case .de: return "Vorlagen verwalten…"
        case .it: return "Gestisci preset…"
        }
    }
    var menuPresetsEmpty: String {
        switch language {
        case .fr: return "Aucun profil enregistré"
        case .en: return "No saved preset"
        case .es: return "Ningún perfil guardado"
        case .de: return "Keine gespeicherte Vorlage"
        case .it: return "Nessun preset salvato"
        }
    }
    var dialogPresetNameTitle: String {
        switch language {
        case .fr: return "Nom du profil"
        case .en: return "Preset name"
        case .es: return "Nombre del perfil"
        case .de: return "Vorlagenname"
        case .it: return "Nome preset"
        }
    }
    var dialogPresetNamePrompt: String {
        switch language {
        case .fr: return "Ex : Tournage A-cam — xxHash + éjection"
        case .en: return "E.g.: A-cam shoot — xxHash + eject"
        case .es: return "Ej.: Rodaje A-cam — xxHash + expulsar"
        case .de: return "Z. B.: A-Cam-Dreh — xxHash + Auswerfen"
        case .it: return "Es.: Ripresa A-cam — xxHash + espulsione"
        }
    }
    var buttonSave: String {
        switch language {
        case .fr: return "Enregistrer"
        case .en: return "Save"
        case .es: return "Guardar"
        case .de: return "Speichern"
        case .it: return "Salva"
        }
    }
    var buttonCancel: String {
        switch language {
        case .fr: return "Annuler"
        case .en: return "Cancel"
        case .es: return "Cancelar"
        case .de: return "Abbrechen"
        case .it: return "Annulla"
        }
    }
    var buttonDelete: String {
        switch language {
        case .fr: return "Supprimer"
        case .en: return "Delete"
        case .es: return "Eliminar"
        case .de: return "Löschen"
        case .it: return "Elimina"
        }
    }
    var buttonClose: String {
        switch language {
        case .fr: return "Fermer"
        case .en: return "Close"
        case .es: return "Cerrar"
        case .de: return "Schließen"
        case .it: return "Chiudi"
        }
    }
    func logPresetApplied(_ name: String) -> String {
        switch language {
        case .fr: return "Profil appliqué — \(name)"
        case .en: return "Preset applied — \(name)"
        case .es: return "Perfil aplicado — \(name)"
        case .de: return "Vorlage angewendet — \(name)"
        case .it: return "Preset applicato — \(name)"
        }
    }
    func logPresetSaved(_ name: String) -> String {
        switch language {
        case .fr: return "Profil enregistré — \(name)"
        case .en: return "Preset saved — \(name)"
        case .es: return "Perfil guardado — \(name)"
        case .de: return "Vorlage gespeichert — \(name)"
        case .it: return "Preset salvato — \(name)"
        }
    }

    var buttonVerifyMHL: String {
        switch language {
        case .fr: return "Vérifier MHL…"
        case .en: return "Verify MHL…"
        case .es: return "Verificar MHL…"
        case .de: return "MHL verifizieren…"
        case .it: return "Verifica MHL…"
        }
    }
    var panelVerifyTitle: String {
        switch language {
        case .fr: return "Choisir un fichier MHL à vérifier"
        case .en: return "Choose an MHL file to verify"
        case .es: return "Elegir un archivo MHL para verificar"
        case .de: return "MHL-Datei zur Verifikation auswählen"
        case .it: return "Scegli un file MHL da verificare"
        }
    }
    var panelChooseSourceTitle: String {
        switch language {
        case .fr: return "Dossier source contenant les fichiers"
        case .en: return "Source folder containing the files"
        case .es: return "Carpeta origen con los archivos"
        case .de: return "Quellordner mit den Dateien"
        case .it: return "Cartella sorgente contenente i file"
        }
    }
    func logVerifyStart(_ name: String) -> String {
        switch language {
        case .fr: return "Vérification du MHL — \(name)"
        case .en: return "Verifying MHL — \(name)"
        case .es: return "Verificando MHL — \(name)"
        case .de: return "MHL verifizieren — \(name)"
        case .it: return "Verifica MHL — \(name)"
        }
    }
    func logVerifyParseFailed(_ reason: String) -> String {
        switch language {
        case .fr: return "Lecture du MHL impossible — \(reason)"
        case .en: return "Could not parse MHL — \(reason)"
        case .es: return "No se pudo leer el MHL — \(reason)"
        case .de: return "MHL konnte nicht analysiert werden — \(reason)"
        case .it: return "Impossibile analizzare MHL — \(reason)"
        }
    }
    func logVerifyMatch(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — checksum OK"
        case .en: return "\(name) — checksum OK"
        case .es: return "\(name) — checksum OK"
        case .de: return "\(name) — Prüfsumme OK"
        case .it: return "\(name) — checksum OK"
        }
    }
    func logVerifyMismatch(_ name: String, expected: String, found: String) -> String {
        let e = String(expected.prefix(12))
        let f = String(found.prefix(12))
        switch language {
        case .fr: return "\(name) — corrompu (attendu \(e)… reçu \(f)…)"
        case .en: return "\(name) — corrupted (expected \(e)… got \(f)…)"
        case .es: return "\(name) — corrupto (esperado \(e)… recibido \(f)…)"
        case .de: return "\(name) — corrupted (expected \(e)… got \(f)…)"
        case .it: return "\(name) — corrupted (expected \(e)… got \(f)…)"
        }
    }
    func logVerifyMissing(_ name: String) -> String {
        switch language {
        case .fr: return "\(name) — fichier manquant"
        case .en: return "\(name) — missing file"
        case .es: return "\(name) — archivo faltante"
        case .de: return "\(name) — Datei nicht gefunden"
        case .it: return "\(name) — file non trovato"
        }
    }
    func logVerifyReadError(_ name: String, _ reason: String) -> String {
        switch language {
        case .fr: return "\(name) — erreur lecture — \(reason)"
        case .en: return "\(name) — read error — \(reason)"
        case .es: return "\(name) — error lectura — \(reason)"
        case .de: return "\(name) — read error — \(reason)"
        case .it: return "\(name) — read error — \(reason)"
        }
    }
    func logVerifyDoneOK(_ count: Int) -> String {
        switch language {
        case .fr: return "Vérification terminée — \(count) fichier(s) intacts"
        case .en: return "Verification finished — \(count) file(s) intact"
        case .es: return "Verificación terminada — \(count) archivo(s) intactos"
        case .de: return "Verifizierung abgeschlossen — \(count) Datei(en) intakt"
        case .it: return "Verifica completata — \(count) file intatto/i"
        }
    }
    func logVerifyDoneWithErrors(_ count: Int) -> String {
        switch language {
        case .fr: return "Vérification terminée — \(count) problème(s) détecté(s)"
        case .en: return "Verification finished — \(count) issue(s) detected"
        case .es: return "Verificación terminada — \(count) problema(s) detectado(s)"
        case .de: return "Verifizierung abgeschlossen — \(count) Problem(e) erkannt"
        case .it: return "Verifica completata — \(count) problema/i rilevato/i"
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
        case .de: return "Volume \(name) — internal:\(i) removable:\(r) ejectable:\(e)"
        case .it: return "Volume \(name) — internal:\(i) removable:\(r) ejectable:\(e)"
        }
    }
    func logEjectFailed(_ name: String, _ reason: String) -> String {
        switch language {
        case .fr: return "Éjection impossible — \(name) — \(reason)"
        case .en: return "Eject failed — \(name) — \(reason)"
        case .es: return "Expulsión fallida — \(name) — \(reason)"
        case .de: return "Auswurf fehlgeschlagen — \(name) — \(reason)"
        case .it: return "Espulsione fallita — \(name) — \(reason)"
        }
    }
    func logEjectSkippedErrors(_ name: String) -> String {
        switch language {
        case .fr: return "Éjection annulée pour \(name) — erreurs durant la copie"
        case .en: return "Eject cancelled for \(name) — errors during copy"
        case .es: return "Expulsión cancelada para \(name) — errores durante la copia"
        case .de: return "Auswurf abgebrochen für \(name) — Fehler während der Kopie"
        case .it: return "Espulsione annullata per \(name) — errori durante la copia"
        }
    }
    var logNoRemovableSource: String {
        switch language {
        case .fr: return "Éjection ignorée — aucune source amovible détectée"
        case .en: return "Eject skipped — no removable source detected"
        case .es: return "Expulsión omitida — sin origen extraíble detectado"
        case .de: return "Auswurf übersprungen — kein entfernbares Quellgerät erkannt"
        case .it: return "Espulsione saltata — nessuna sorgente rimovibile rilevata"
        }
    }
    func notifSuccess(_ verified: Int, _ total: Int) -> String {
        switch language {
        case .fr: return "Copie terminée — \(verified)/\(total) vérifié(s)"
        case .en: return "Copy finished — \(verified)/\(total) verified"
        case .es: return "Copia terminada — \(verified)/\(total) verificados"
        case .de: return "Kopie abgeschlossen — \(verified)/\(total) verifiziert"
        case .it: return "Copia completata — \(verified)/\(total) verificato/i"
        }
    }
    func notifFailure(_ failed: Int) -> String {
        switch language {
        case .fr: return "Terminé avec \(failed) erreur(s)"
        case .en: return "Finished with \(failed) error(s)"
        case .es: return "Terminado con \(failed) error(es)"
        case .de: return "Abgeschlossen mit \(failed) Fehler(n)"
        case .it: return "Completato con \(failed) errore/i"
        }
    }
    var labelSpeed: String {
        switch language {
        case .fr: return "Vitesse"
        case .en: return "Speed"
        case .es: return "Velocidad"
        case .de: return "Geschwindigkeit"
        case .it: return "Velocità"
        }
    }
    var toggleEject: String {
        switch language {
        case .fr: return "Éjecter la carte après copie"
        case .en: return "Eject card after copy"
        case .es: return "Expulsar tarjeta tras copia"
        case .de: return "Karte nach dem Kopieren auswerfen"
        case .it: return "Espelli scheda dopo la copia"
        }
    }
    var toggleNotify: String {
        switch language {
        case .fr: return "Notification système"
        case .en: return "System notification"
        case .es: return "Notificación del sistema"
        case .de: return "Systembenachrichtigung"
        case .it: return "Notifica di sistema"
        }
    }
    var toggleSkipSystem: String {
        switch language {
        case .fr: return "Ignorer fichiers système"
        case .en: return "Skip system files"
        case .es: return "Omitir archivos de sistema"
        case .de: return "Systemdateien überspringen"
        case .it: return "Salta file di sistema"
        }
    }
    var sourcesEmptyTitle: String {
        switch language {
        case .fr: return "Aucune source"
        case .en: return "No source"
        case .es: return "Ningún origen"
        case .de: return "Keine Quelle"
        case .it: return "Nessuna sorgente"
        }
    }
    var sourcesEmptySubtitle: String {
        switch language {
        case .fr: return "Glissez une ou plusieurs sources — cartes ou dossiers"
        case .en: return "Drop one or several sources — cards or folders"
        case .es: return "Arrastra uno o varios orígenes — tarjetas o carpetas"
        case .de: return "Eine oder mehrere Quellen ablegen — Karten oder Ordner"
        case .it: return "Trascina una o più sorgenti — schede o cartelle"
        }
    }
    var sourceAddTitle: String {
        switch language {
        case .fr: return "Ajouter une source"
        case .en: return "Add a source"
        case .es: return "Añadir un origen"
        case .de: return "Quelle hinzufügen"
        case .it: return "Aggiungi sorgente"
        }
    }
    func cardDetected(_ name: String) -> String {
        switch language {
        case .fr: return "Carte détectée — \(name)"
        case .en: return "Card detected — \(name)"
        case .es: return "Tarjeta detectada — \(name)"
        case .de: return "Karte erkannt — \(name)"
        case .it: return "Scheda rilevata — \(name)"
        }
    }
    var addAsSource: String {
        switch language {
        case .fr: return "Ajouter comme source"
        case .en: return "Add as source"
        case .es: return "Añadir como origen"
        case .de: return "Als Quelle hinzufügen"
        case .it: return "Aggiungi come sorgente"
        }
    }
    var dismiss: String {
        switch language {
        case .fr: return "Ignorer"
        case .en: return "Dismiss"
        case .es: return "Ignorar"
        case .de: return "Verwerfen"
        case .it: return "Ignora"
        }
    }

    // MARK: - File status labels
    func fileStatusLabel(_ status: FileStatus) -> String {
        switch (status, language) {
        case (.pending, .fr): return "En attente"
        case (.pending, .en): return "Pending"
        case (.pending, .es): return "En espera"
        case (.pending, .de): return "Ausstehend"
        case (.pending, .it): return "In attesa"
        case (.copying, .fr): return "Copie…"
        case (.copying, .en): return "Copying…"
        case (.copying, .es): return "Copiando…"
        case (.copying, .de): return "Kopieren…"
        case (.copying, .it): return "Copia…"
        case (.verifying, .fr): return "Vérification…"
        case (.verifying, .en): return "Verifying…"
        case (.verifying, .es): return "Verificando…"
        case (.verifying, .de): return "Verifizieren…"
        case (.verifying, .it): return "Verifica…"
        case (.copied, .fr): return "Copié"
        case (.copied, .en): return "Copied"
        case (.copied, .es): return "Copiado"
        case (.copied, .de): return "Kopiert"
        case (.copied, .it): return "Copiato"
        case (.verified, .fr): return "Vérifié"
        case (.verified, .en): return "Verified"
        case (.verified, .es): return "Verificado"
        case (.verified, .de): return "Verifiziert"
        case (.verified, .it): return "Verificato"
        case (.failed(let reason), .fr): return "Erreur — \(reason)"
        case (.failed(let reason), .en): return "Error — \(reason)"
        case (.failed(let reason), .es): return "Error — \(reason)"
        case (.failed(let reason), .de): return "Fehler — \(reason)"
        case (.failed(let reason), .it): return "Errore — \(reason)"
        case (.skipped, .fr): return "Ignoré"
        case (.skipped, .en): return "Skipped"
        case (.skipped, .es): return "Omitido"
        case (.skipped, .de): return "Übersprungen"
        case (.skipped, .it): return "Saltato"
        }
    }
}
