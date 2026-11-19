package fr.veilleuse.lanceur

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Écran d'accueil « Veilleuse » du projecteur (ADR 0025).
 *
 * Tout le dessin est en Flutter ; ce côté Android ne fait que ce que Dart ne
 * peut pas faire seul : lister les applis lançables, lancer une appli, ouvrir
 * un écran de réglages (y compris ceux du fabricant : trapèze, mise au point)
 * et lire la mémoire. Aucune permission particulière, aucun root.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "veilleuse/systeme")
            .setMethodCallHandler { appel, reponse ->
                when (appel.method) {
                    "applis" -> reponse.success(applis())
                    "icone" -> reponse.success(icone(appel.argument<String>("paquet")!!))
                    "lancer" -> reponse.success(lancer(appel.argument<String>("paquet")!!))
                    "ouvrir" -> reponse.success(
                        ouvrir(appel.argument<String>("action"), appel.argument<String>("composant"))
                    )
                    "memoire" -> reponse.success(memoire())
                    "lirePref" -> reponse.success(prefs().getString(appel.argument<String>("cle"), null))
                    "ecrirePref" -> {
                        prefs().edit()
                            .putString(appel.argument<String>("cle"), appel.argument<String>("valeur"))
                            .apply()
                        reponse.success(null)
                    }
                    else -> reponse.notImplemented()
                }
            }
    }

    private fun prefs() = getSharedPreferences("veilleuse", Context.MODE_PRIVATE)

    /** Applis lançables : celles prévues pour la TV d'abord, puis les autres. */
    private fun applis(): List<Map<String, Any>> {
        val vus = LinkedHashMap<String, Map<String, Any>>()
        for ((categorie, tv) in listOf(
            Intent.CATEGORY_LEANBACK_LAUNCHER to true,
            Intent.CATEGORY_LAUNCHER to false,
        )) {
            val intention = Intent(Intent.ACTION_MAIN).addCategory(categorie)
            for (info in packageManager.queryIntentActivities(intention, 0)) {
                val paquet = info.activityInfo.packageName
                if (paquet == packageName || vus.containsKey(paquet)) continue
                vus[paquet] = mapOf(
                    "paquet" to paquet,
                    "nom" to info.loadLabel(packageManager).toString(),
                    "tv" to tv,
                )
            }
        }
        return vus.values.toList()
    }

    /** Bannière TV si l'appli en a une, sinon son icône, en PNG. */
    private fun icone(paquet: String): ByteArray? = try {
        val image = packageManager.getApplicationBanner(paquet)
            ?: packageManager.getApplicationIcon(paquet)
        enPng(image)
    } catch (e: PackageManager.NameNotFoundException) {
        null
    }

    private fun enPng(image: Drawable): ByteArray {
        val bitmap = if (image is BitmapDrawable && image.bitmap != null) {
            image.bitmap
        } else {
            // Icônes adaptatives ou vectorielles : on les dessine à 320 × 180
            // au plus, assez pour une tuile en 720p, sans gâcher de mémoire.
            val l = image.intrinsicWidth.coerceIn(1, 320)
            val h = image.intrinsicHeight.coerceIn(1, 180)
            Bitmap.createBitmap(l, h, Bitmap.Config.ARGB_8888).also {
                val toile = Canvas(it)
                image.setBounds(0, 0, l, h)
                image.draw(toile)
            }
        }
        return ByteArrayOutputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            it.toByteArray()
        }
    }

    private fun lancer(paquet: String): Boolean {
        val intention = packageManager.getLeanbackLaunchIntentForPackage(paquet)
            ?: packageManager.getLaunchIntentForPackage(paquet)
            ?: return false
        return demarrer(intention)
    }

    /**
     * Ouvre un écran de réglages, par action (« android.settings.WIFI_SETTINGS »)
     * ou par composant explicite (« paquet/.Activite ») pour les réglages du
     * fabricant. Renvoie false si rien ne répond : Dart essaie alors la suite.
     */
    private fun ouvrir(action: String?, composant: String?): Boolean {
        val intention = when {
            composant != null -> {
                val nom = ComponentName.unflattenFromString(composant) ?: return false
                Intent().setComponent(nom)
            }
            action != null -> Intent(action)
            else -> return false
        }
        return demarrer(intention)
    }

    private fun demarrer(intention: Intent): Boolean = try {
        startActivity(intention.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        // ActivityNotFoundException ou SecurityException (activité non exportée).
        false
    }

    private fun memoire(): Map<String, Long> {
        val info = ActivityManager.MemoryInfo()
        (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
        return mapOf("disponible" to info.availMem, "totale" to info.totalMem)
    }
}
